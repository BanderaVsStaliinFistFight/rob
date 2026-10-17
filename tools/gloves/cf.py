import numpy as np
def cf_from_xml(e):
    v={c.tag:float(c.text) for c in e}
    M=np.eye(4)
    M[:3,:3]=[[v['R00'],v['R01'],v['R02']],[v['R10'],v['R11'],v['R12']],[v['R20'],v['R21'],v['R22']]]
    M[:3,3]=[v['X'],v['Y'],v['Z']]
    return M
def inv(M):
    R=M[:3,:3]; t=M[:3,3]; N=np.eye(4); N[:3,:3]=R.T; N[:3,3]=-R.T@t; return N
def T(x,y,z):
    M=np.eye(4); M[:3,3]=[x,y,z]; return M
def rotY(a):
    c,s=np.cos(a),np.sin(a); M=np.eye(4); M[:3,:3]=[[c,0,s],[0,1,0],[-s,0,c]]; return M
def rotZ(a):
    c,s=np.cos(a),np.sin(a); M=np.eye(4); M[:3,:3]=[[c,-s,0],[s,c,0],[0,0,1]]; return M
