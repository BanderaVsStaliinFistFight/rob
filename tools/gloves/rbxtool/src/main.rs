use std::fs::File;
use std::io::{BufReader, BufWriter};

use rbx_dom_weak::{InstanceBuilder, WeakDom};
use rbx_types::{
    Attributes, CFrame, Color3uint8, Enum, EnumItem, Matrix3, Ref, Variant, Vector3,
};

fn cframe(rows: &serde_json::Value) -> CFrame {
    let r: Vec<Vec<f32>> = rows
        .as_array()
        .unwrap()
        .iter()
        .map(|row| row.as_array().unwrap().iter().map(|v| v.as_f64().unwrap() as f32).collect())
        .collect();
    CFrame::new(
        Vector3::new(r[0][3], r[1][3], r[2][3]),
        Matrix3::new(
            Vector3::new(r[0][0], r[0][1], r[0][2]),
            Vector3::new(r[1][0], r[1][1], r[1][2]),
            Vector3::new(r[2][0], r[2][1], r[2][2]),
        ),
    )
}

fn find_child(dom: &WeakDom, parent: Ref, name: &str) -> Option<Ref> {
    dom.get_by_ref(parent)?
        .children()
        .iter()
        .copied()
        .find(|r| dom.get_by_ref(*r).map_or(false, |i| i.name == name))
}

/// Adds the glove parts described by the fit spec to each arm model, welded to its Middle part.
fn add_gloves(dom: &mut WeakDom, spec: &serde_json::Value) {
    for part in spec["parts"].as_array().unwrap() {
        let arm_name = part["arm"].as_str().unwrap();
        let arm = dom
            .descendants()
            .find(|i| i.class == "Model" && i.name == arm_name)
            .map(|i| i.referent())
            .unwrap_or_else(|| panic!("arm model {arm_name} not found"));
        let middle = find_child(dom, arm, "Middle").expect("Middle part");
        let template = dom.get_by_ref(middle).unwrap().properties.clone();
        let weld_template = dom
            .get_by_ref(middle)
            .unwrap()
            .children()
            .iter()
            .map(|r| dom.get_by_ref(*r).unwrap())
            .find(|i| i.class == "Weld")
            .expect("weld template")
            .properties
            .clone();

        let name = part["name"].as_str().unwrap();
        let cuff = name == "GloveCuff";
        let shape = match part["shape"].as_str().unwrap() {
            "Ball" => 0,
            "Block" => 1,
            "Cylinder" => 2,
            other => panic!("unknown shape {other}"),
        };
        let size: Vec<f32> = part["size"]
            .as_array()
            .unwrap()
            .iter()
            .map(|v| v.as_f64().unwrap() as f32)
            .collect();
        let color = if cuff {
            Color3uint8::new(52, 52, 58)
        } else {
            Color3uint8::new(27, 27, 30)
        };
        const LEATHER: u32 = 2309;
        let mut attributes = Attributes::new();
        attributes.insert(
            "OriginalMaterial".to_owned(),
            Variant::EnumItem(EnumItem { ty: "Material".to_owned(), value: LEATHER }),
        );
        attributes.insert("OriginalMaterialVariant".to_owned(), Variant::String(String::new()));

        let mut builder = InstanceBuilder::new("Part");
        for (k, v) in template.iter() {
            builder = builder.with_property(*k, v.clone());
        }
        let builder = builder
            .with_name(name)
            .with_property("CFrame", cframe(&part["world"]))
            .with_property("Size", Vector3::new(size[0], size[1], size[2]))
            .with_property("Shape", Enum::from_u32(shape))
            .with_property("Color", color)
            .with_property("Material", Enum::from_u32(LEATHER))
            .with_property("Transparency", 0.0f32)
            .with_property("Massless", true)
            .with_property("CastShadow", true)
            .with_property("Attributes", attributes);
        let glove = dom.insert(arm, builder);

        let mut weld = InstanceBuilder::new("Weld");
        for (k, v) in weld_template.iter() {
            weld = weld.with_property(*k, v.clone());
        }
        let weld = weld
            .with_name("Weld")
            .with_property("Part0", middle)
            .with_property("Part1", glove)
            .with_property("C0", cframe(&part["c0"]))
            .with_property("C1", CFrame::new(Vector3::new(0.0, 0.0, 0.0), Matrix3::identity()));
        dom.insert(middle, weld);
    }
}

/// Usage:
///   rbxtool toxml <in.rbxm> <out.rbxmx>
///   rbxtool gloves <in.rbxm> <spec.json> <out.rbxm>
fn main() {
    let args: Vec<String> = std::env::args().collect();
    let read = |path: &str| rbx_binary::from_reader(BufReader::new(File::open(path).unwrap())).unwrap();
    match args.get(1).map(String::as_str) {
        Some("toxml") => {
            let dom = read(&args[2]);
            let out = BufWriter::new(File::create(&args[3]).unwrap());
            rbx_xml::to_writer_default(out, &dom, dom.root().children()).unwrap();
        }
        Some("gloves") => {
            let mut dom = read(&args[2]);
            let spec: serde_json::Value =
                serde_json::from_reader(BufReader::new(File::open(&args[3]).unwrap())).unwrap();
            add_gloves(&mut dom, &spec);
            let out = BufWriter::new(File::create(&args[4]).unwrap());
            let top: Vec<Ref> = dom.root().children().to_vec();
            rbx_binary::to_writer(out, &dom, &top).unwrap();
        }
        _ => {
            eprintln!("usage: rbxtool toxml <in.rbxm> <out.rbxmx> | gloves <in.rbxm> <spec.json> <out.rbxm>");
            std::process::exit(2);
        }
    }
}
