// Persistence of Vision Ray Tracer Scene Description File
// File: GrandPerspectiveLogo.pov
// Vers: 3.5
// Desc: The logo for the GrandPerspective application
// Date: 16/08/2005
// Auth: Erwin Bonsma
//

#version 3.5;
#include "colors.inc"
global_settings {
  assumed_gamma 1.0
}
// ----------------------------------------
#declare Eps = <1, 0, 1> * 0.01;

#declare Color1 = NavyBlue;
#declare Color2 = SkyBlue;
#declare Color3 = MediumTurquoise;
#declare Color5 = Cyan * 0.8; //DarkSlateBlue;
#declare Color4 = Blue; //Cyan;

#macro rbox(v0, v1)
  #local R = 0.02;
  #local H = v1.y - v0.y; 
  #local P1 = <v0.x + R, v1.y, v0.z + R>;
  #local P2 = <v0.x + R, v1.y, v1.z - R>;
  #local P4 = <v1.x - R, v1.y, v0.z + R>;
  #local P3 = <v1.x - R, v1.y, v1.z - R>;
  union {
    // top
    sphere { P1, R }
    sphere { P2, R }
    sphere { P3, R }
    sphere { P4, R }
    cylinder { P1, P2, R open }
    cylinder { P2, P3, R open }
    cylinder { P3, P4, R open }
    cylinder { P4, P1, R open }
    box { P1, P3+R*y }

    // sides
    cylinder { P1-H*y, P1, R open }
    cylinder { P2-H*y, P2, R open }
    cylinder { P3-H*y, P3, R open }
    cylinder { P4-H*y, P4, R open }
    box { P1-R*x, P3+R*x-H*y }    
    box { P1-R*z, P3+R*z-H*y }
  } 
#end

camera {
  location  <2.8, 4, 2.4> * 0.39
  right     x // sets aspect ration of 1:1
  look_at   <0.0, -0.14,  0.0>
}
light_source {
  <0, 0, 0>            // light's position (translated below)
  color rgb <1, 1, 1>  * 1.2// light's color
  translate <3, 8, 5>  * 0.2
}

// box { <0, 0, 0>, <0.5, 1, 0.5> }
union {
  rbox(<0.00, 0, 0.00>, <0.25, 0.90, 0.30>)
  rbox(<0.00, 0, 0.30>, <0.25, 0.90, 0.38>)
  rbox(<0.00, 0, 0.38>, <0.25, 0.90, 0.44>)
  rbox(<0.00, 0, 0.44>, <0.25, 0.90, 0.50>)
  rbox(<0.25, 0, 0.00>, <0.50, 0.90, 0.15>)
  rbox(<0.25, 0, 0.15>, <0.50, 0.90, 0.25>)
  rbox(<0.25, 0, 0.25>, <0.35, 0.90, 0.50>)
  rbox(<0.35, 0, 0.25>, <0.50, 0.90, 0.40>)
  rbox(<0.35, 0, 0.40>, <0.50, 0.90, 0.50>)
  texture {
    pigment { Color1 }
    finish { phong 0.9 phong_size 60 }
  }
}

// box { <0.5, 0, 0>, <0.8, 0.7, 0.3> }
union {
  rbox(<0.50, 0, 0.0>, <0.67, 0.70, 0.2>)
  rbox(<0.67, 0, 0.0>, <0.80, 0.70, 0.2>)
  rbox(<0.50, 0, 0.2>, <0.63, 0.70, 0.3>)
  rbox(<0.63, 0, 0.2>, <0.80, 0.70, 0.3>)
  texture {
    pigment { Color2 }
    finish { phong 0.9 phong_size 60 }
  }
}

// box { <0.5, 0, 0.3>, <0.7, 0.4, 0.5> }
union {
  rbox(<0.50, 0, 0.30>, <0.62, 0.40, 0.38>)
  rbox(<0.50, 0, 0.38>, <0.62, 0.40, 0.50>)
  rbox(<0.62, 0, 0.30>, <0.70, 0.40, 0.42>)
  rbox(<0.62, 0, 0.42>, <0.70, 0.40, 0.50>)
  texture {
    pigment { Color3 }
    finish { phong 0.9 phong_size 60 }
  }
}


// box { <0, 0, 0.5>, <0.7, 0.5, 0.7> }
union {
  rbox(<0.00, 0, 0.50>, <0.20, 0.50, 0.70>)
  rbox(<0.20, 0, 0.50>, <0.40, 0.50, 0.70>)
  rbox(<0.40, 0, 0.50>, <0.51, 0.50, 0.59>)
  rbox(<0.40, 0, 0.59>, <0.51, 0.50, 0.70>)
  rbox(<0.51, 0, 0.50>, <0.60, 0.50, 0.62>)
  rbox(<0.51, 0, 0.62>, <0.60, 0.50, 0.70>)
  rbox(<0.60, 0, 0.50>, <0.70, 0.50, 0.60>)
  rbox(<0.60, 0, 0.60>, <0.70, 0.50, 0.70>)
  texture {
    pigment { Color4 }
    finish { phong 0.9 phong_size 60 }
  }
}

// box { <0.7, 0, 0.3>, <0.8, 0.2, 0.7> }
union {
  rbox(<0.7, 0, 0.3>, <0.8, 0.22, 0.45>)
  rbox(<0.7, 0, 0.45>, <0.8, 0.21, 0.6>)
  rbox(<0.7, 0, 0.6>, <0.8, 0.2, 0.7>)
  texture {
    pigment { Color5 }
    finish { phong 0.9 phong_size 60 }
  }
}
