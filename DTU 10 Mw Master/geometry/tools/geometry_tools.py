"""
Basic methods to read, write and manipulate the DTU 10MW RWT 3D geometry

The scripts require python 2.7.x, numpy and fortranfile to read/write the geometry
and mayavi to plot it.

To plot the turbine in Mayavi start ipython with the --pylab option
and type "run geometry_tools.py".

author: Frederik Zahle (frza@dtu.dk)
date: 29.03.2013
version: 1.01
"""

import copy
import numpy as np

def dotX(rot, x, trans_vect=np.array([0.0,0.0,0.0])):
    """
    Transpose and multiply the x array by a rotational matrix
    """
    if isinstance(x,list):
        x_tmp = np.array([x[0].flatten(), x[1].flatten(), x[2].flatten()]).T
        x_rot_tmp = np.zeros(x_tmp.shape)
        for i in range(x_tmp.shape[0]):
            x_rot_tmp[i,:] = np.dot(rot, x_tmp[i,:] - trans_vect)

        x_rot = []
        for iX in range(3):
            x_rot.append(x_rot_tmp[:,iX].reshape(x[0].shape))
    elif isinstance(x,np.ndarray):
        x_rot = np.zeros(x.shape)
        if len(x.shape)==2:
            for i in range(x.shape[0]):
                x_rot[i,:] = np.dot(rot, x[i,:] - trans_vect)
        elif len(x.shape)==3:
            for i in range(x.shape[0]):
                for j in range(x.shape[1]):
                    x_rot[i,j,:] = np.dot(rot, x[i,j,:] - trans_vect)

    return x_rot

# rotation matrix function in the X direction
RotX = lambda a: np.array([[1,         0,        0           ],
                           [0,       np.cos(a),   -np.sin(a) ],
                           [0,       np.sin(a),   np.cos(a)  ]])
# rotation matrix function in the Y direction
RotY = lambda a: np.array([[np.cos(a),    0,      np.sin(a)  ],
                           [0,            1,        0        ],
                           [-np.sin(a),   0,      np.cos(a)  ]])
# rotation matrix function in the Z direction
RotZ = lambda a: np.array([[np.cos(a),  -np.sin(a),    0     ],
                           [np.sin(a),   np.cos(a),    0     ],
                           [0,               0,        1     ]])

deg2rad = np.pi / 180.

class Domain(object):
    """
    Domain object that holds a list of Block objects

    The class has methods to rotate the domain about the x, y, and z axes
    and plot the surface.
    """

    def __init__(self):

        self.blocks = []

    def add_blocks(self,b):

        if not isinstance(b,list):
            b = [b]
        self.blocks.extend(b)
        self.nb = len(self.blocks)

    def add_domain(self,d):

        for b in d.blocks:
            self.blocks.extend([copy.deepcopy(b)])

        self.nb = len(self.blocks)

    def translate_x(self,x,blocks=[],copy=False):

        blocks = self._set_blocks(blocks,copy)

        for n in blocks:
            b = self.blocks[n]
            b.translate_x(x)

    def translate_y(self,x,blocks=[],copy=False):

        blocks = self._set_blocks(blocks,copy)

        for n in blocks:
            b = self.blocks[n]
            b.translate_y(x)

    def translate_z(self,x,blocks=[],copy=False):

        blocks = self._set_blocks(blocks,copy)

        for n in blocks:
            b = self.blocks[n]
            b.translate_z(x)

    def rotate_x(self,deg,blocks=[],copy=False):

        blocks = self._set_blocks(blocks,copy)

        for n in blocks:
            b = self.blocks[n]
            b.rotate_x(deg)

    def rotate_y(self,deg,blocks=[],copy=False):

        blocks = self._set_blocks(blocks,copy)

        for n in blocks:
            b = self.blocks[n]
            b.rotate_y(deg)

    def rotate_z(self,deg,blocks=[],copy=False):

        blocks = self._set_blocks(blocks,copy)

        for n in blocks:
            b = self.blocks[n]
            b.rotate_z(deg)

    def _set_blocks(self,blocks=[],copy=False):

        if blocks == []:
            blocks = range(self.nb)

        if not isinstance(blocks,list):
            raise ('blocks needs to be specified as a list')

        if copy:
            bs = len(blocks)
            nb = self.nb
            self.copy(blocks=blocks)
            blocks = range(nb,self.nb)

        return blocks


    def copy(self,blocks=[]):

        if blocks == []:
            blocks = range(self.nb)

        for i in blocks:
            self.blocks.extend([copy.deepcopy(self.blocks[i])])
            count = sum([self.blocks[c].name.find(self.blocks[i].name) == 0 for c in range(self.nb)])
            self.blocks[-1].name = self.blocks[i].name+'-copy'+str(count)
            self.nb += 1

    def plot_surface_grid(self, layer=0, mesh=True, col=(0,0,0), scale=0.01):

        try:
            from enthought.tvtk.api import tvtk
            from enthought.mayavi import mlab
        except:
            raise "install tvtk and mayavi to plot"

        fig = mlab.figure(mlab,bgcolor=(1,1,1))
        for n,block in enumerate(self.blocks):
            xall = np.zeros((block.ni*block.nj,3))
            xall[:,0] = block.x[:,:,layer].swapaxes(0,1).flatten()
            xall[:,1] = block.y[:,:,layer].swapaxes(0,1).flatten()
            xall[:,2] = block.z[:,:,layer].swapaxes(0,1).flatten()

            sgrid = tvtk.StructuredGrid(dimensions=(block.ni,block.nj,1))
            sgrid.points = xall
            d = mlab.pipeline.add_dataset(sgrid)
            gx = mlab.pipeline.grid_plane(d,color=col,line_width=1.0)
            surf = mlab.mesh(block.x[:,:,layer]
                            ,block.y[:,:,layer]
                            ,block.z[:,:,layer],color=(1,1,1))

    def plot_surface(self,layer=0,color=(30/255.,80/255.,200/255.)):

        try:
            from enthought.tvtk.api import tvtk
            from enthought.mayavi import mlab
        except:
            raise "install tvtk and mayavi to plot"

        fig = mlab.figure(mlab,bgcolor=(1,1,1))

        for n,block in enumerate(self.blocks):
            surf = mlab.mesh(block.x[:,:,layer]
                            ,block.y[:,:,layer]
                            ,block.z[:,:,layer],color=color)


class Block(object):
    """
    Class that holds a single 3D grid with dimensions ni, nj, nk
    """

    def __init__(self,x,y,z,name='block'):

        self.name = name
        shape = x.shape
        if len(shape) == 3:
            self.ni, self.nj, self.nk = shape
            self.x = x
            self.y = y
            self.z = z
        elif len(shape) == 2:
            self.ni, self.nj = shape
            self.nk = 1
            self.x = np.zeros([self.ni,self.nj,1])
            self.y = np.zeros([self.ni,self.nj,1])
            self.z = np.zeros([self.ni,self.nj,1])
            self.x[:,:,0] = x
            self.y[:,:,0] = y
            self.z[:,:,0] = z

    def translate_x(self,x):

        self.x += x

    def translate_y(self,y):

        self.y += y

    def translate_z(self,z):

        self.z += z

    def rotate_x(self,deg):

        self._rotate(deg,RotX)

    def rotate_y(self,deg):

        self._rotate(deg,RotY)

    def rotate_z(self,deg):

        self._rotate(deg,RotZ)

    def _rotate(self,deg,Rot):

        deg *= deg2rad
        xt = np.array([self.x.flatten(),self.y.flatten(),self.z.flatten()]).swapaxes(0,1)
        xt = np.zeros((self.ni*self.nj,3))
        xt[:,0] = self.x.swapaxes(0,1).flatten()
        xt[:,1] = self.y.swapaxes(0,1).flatten()
        xt[:,2] = self.z.swapaxes(0,1).flatten()
        x = dotX(Rot(deg),xt)
        # split into x, y, z and reshape into ni, nj, nk
        self.x = x[:,0].reshape(self.nk,self.nj,self.ni).swapaxes(0,2)
        self.y = x[:,1].reshape(self.nk,self.nj,self.ni).swapaxes(0,2)
        self.z = x[:,2].reshape(self.nk,self.nj,self.ni).swapaxes(0,2)


def read_plot3d(filename,name='block',single_precision=False):
    """
    method to read plot3d multiblock grids

    returns a Domain object
    """

    try:
        from fortranfile import FortranFile
    except:
        raise ('Install fortranfile with the command\n'
              '$ easy_install fortranfile')

    f = FortranFile(filename)

    # read number of blocks
    nb = f.readInts()[0]
    bsizes = f.readInts()
    bsizes = bsizes.reshape(nb,3)

    # create a domain object
    domain = Domain()

    # read per block data
    for n in range(nb):
        ni, nj, nk = bsizes[n,:]
        # read x, y, z data
        if single_precision:
            xt = f.readReals()
        else:
            xt = f.readReals('d')
        # split into blocks
        nt = ni * nj * nk
        xt = xt.reshape(3, nt)
        # split into x, y, z and reshape into ni, nj, nk
        x = xt[0,:].reshape(nk,nj,ni).swapaxes(0,2)
        y = xt[1,:].reshape(nk,nj,ni).swapaxes(0,2)
        z = xt[2,:].reshape(nk,nj,ni).swapaxes(0,2)
        domain.add_blocks(Block(x,y,z,name=name))
    f.close()

    return domain

def write_plot3d(domain,filename='out.xyz',single_precision=False):
    """
    write a domain to an unformatted plot3d file
    """

    try:
        from fortranfile import FortranFile
    except:
        raise ('Install fortranfile with the command\n'
              '$ easy_install fortranfile')
    f = FortranFile(filename,mode='wb')
    f.writeInts(domain.nb)
    bsizes = []
    for n in range(domain.nb):
        bsizes.extend(domain.blocks[n].x.shape)
    f.writeInts([nis for nis in bsizes])
    for n in range(domain.nb):
        x = domain.blocks[n].x.flatten(order='F')
        x = np.append(x,domain.blocks[n].y.flatten(order='F'))
        x = np.append(x,domain.blocks[n].z.flatten(order='F'))
        if single_precision:
            f.writeReals(x)
        else:
            f.writeReals(x,'d')
    f.close()
    write_plot3d_bnd(domain,filename=filename)

def write_plot3d_bnd(dom,filename='out.xyz'):
    """
    write the plot3d bnd file - only walls are considered
    """

    f = open(filename+'.fvbnd','w')
    f.write('FVBND 1 4\n')
    f.write('wall\n')
    f.write('BOUNDARIES\n')
    for n in range(dom.nb):
        f.write('1 %i %i %i %i %i 1 1 F -1\n'%(n+1,1,dom.blocks[n].ni,1,dom.blocks[n].nj))

    f.close()

def read_ascii_grid(name):
    """read blade coordinates written in flattened ascii"""

    x=np.loadtxt(name+'_X.dat')
    y=np.loadtxt(name+'_Y.dat')
    z=np.loadtxt(name+'_Z.dat')

    b = Block(x,y,z)
    d = Domain()
    d.add_blocks(b)
    return d

"""
convenience routines for building the turbine geometry.
all components are oriented with their primary axes
along z+ and therefore need to be rotated and positioned
relative to each other.

The routines below use a coordinate system in which 
z+ is in the flow direction, blade 1 points towards y+
and rotates clockwise around z+ according to the right hand rule
when looking downstream.
"""

def build_rotor():
    """
    build isolated rotor geometry
    """

    rotor = read_plot3d('../DTU_10MW_RWT_blade3D.xyz')
    rotor.rotate_x(-90)
    rotor.rotate_y(180)
    # add blade 2
    rotor.rotate_z(-120,copy=True)
    # add blade 3
    rotor.rotate_z(120,copy=True,blocks=[0])
    print 'done assembling rotor'

    return rotor

def build_nacelle():

    nacelle = read_plot3d('../DTU_10MW_RWT_nacelle_spinner_3D.xyz',name='spinner')
    # spinner tip is located at z = -6.5
    nacelle.translate_z(-6.5)
    nacelle.rotate_z(-120,copy=True)
    nacelle.rotate_z(120,copy=True,blocks=[0])
    print 'done assembling nacelle' 

    return nacelle

def build_full_wt():

    rotor = read_plot3d('../DTU_10MW_RWT_blade3D_prebend.xyz',name='blade-pb')
    rotor.rotate_x(-90)
    rotor.rotate_y(180)
    # add cone angle of 2.5 deg
    rotor.rotate_x(-2.5)
    # add blade 2
    rotor.rotate_z(-120,copy=True)
    # add blade 3
    rotor.rotate_z(120,copy=True,blocks=[0])
    # add tilt
    rotor.rotate_x(5.)

    spinner = read_plot3d('../DTU_10MW_RWT_spinner3D.xyz',name='spinner')
    # spinner tip is located at z = -6.5
    spinner.translate_z(-6.5)
    # copy and rotate to generate full 3D body
    spinner.rotate_z(-120,copy=True)
    spinner.rotate_z(120,copy=True,blocks=[0])
    # add tilt
    spinner.rotate_x(5.)

    nacelle = read_plot3d('../DTU_10MW_RWT_nacelle3D.xyz',name='nacelle')
    # offset nacelle by same amount as spinner
    nacelle.translate_z(-6.5)
    # copy and rotate to generate full 3D body
    nacelle.rotate_z(-120,copy=True)
    nacelle.rotate_z(120,copy=True,blocks=[0])
    # add tilt
    nacelle.rotate_x(5.)

    tower = read_plot3d('../DTU_10MW_RWT_tower3D.xyz',name='tower')
    # the geometry is defined with the hub at (0,0,0)
    tower.translate_z(-119.)
    tower.rotate_x(-90)
    # tower center to hub center distance is 7.1 m along shaft axis
    # horizontal distance is
    offset = 7.1*np.cos(5.*deg2rad)
    tower.translate_z(offset)
    wt = Domain()
    wt.add_domain(rotor)
    wt.add_domain(spinner)
    wt.add_domain(nacelle)
    wt.add_domain(tower)
    print 'done assembling full wind turbine'

    return wt

if __name__ == '__main__':
#   rotor = build_rotor()
    # write to unformatted plot3d file
#   write_plot3d(rotor,'DTU_10MW_RWT_surface_straight_rotor.xyz')

    # load the rotor baseline grid
#   rotorgrid = read_plot3d('../../CFD/3D_DTU_10MW_RWT/baseline/surfacegrid/grid.xyz')

    # plot the two surfaces on top of each other
#   rotor.plot_surface()
#   rotorgrid.plot_surface(color=(1,0,0))

    # build the rotor nacelle surface
#   nacelle = build_nacelle()
#   rn = Domain()
#   rn.add_domain(rotor)
#   rn.add_domain(nacelle)
#   write_plot3d(rn,'DTU_10MW_RWT_surface_rotor_nacelle.xyz')
#   rngrid = read_plot3d('../../CFD/3D_DTU_10MW_RWT/with_spinner/surfacegrid/grid.xyz')
    # plot the surface grid
#   rngrid.plot_surface_grid()

    # build the full wt with cone, tilt, prebend, separated nacelle/spinner
    wt = build_full_wt()
    # plot 3d surface
    wt.plot_surface()
    # plot a blade section
    # b = wt.blocks[0]
    # import matplotlib.pylab as plt
    # plt.plot(b.x[:,40,0],b.z[:,40,0],'-o')
    # plt.show()
    # write_plot3d(wt,'DTU_10MW_RWT_surface_wt.xyz')

