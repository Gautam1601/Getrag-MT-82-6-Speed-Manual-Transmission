//
// Getrag MT-82 6-Speed Manual Transmission – Improved/Refactored
// By Gautam Sankara Raman
// NOTE: You must have the MCAD involute gear library installed:
//       use <MCAD/involute_gears.scad>
//

//----------------------------
// Global Render Parameters
//----------------------------

use <MCAD/involute_gears.scad>

$fn = 60;               // Smoothness of curved surfaces
cutaway_view = false;   // Cutaway visualization
show_case = false;      // Toggle to display the transmission case

//----------------------------
// Colors
//----------------------------
color_shaft       = "silver";
color_layshaft    = "silver";
color_input_gear  = "darkblue";
color_layshaft_gear = "darkgreen";
color_output_gear = "darkred";
color_reverse_gear = "purple";
color_synchro     = "gold";
color_case        = "lightgray";
color_selector    = "silver";
color_shift_fork  = "darkgray";

//----------------------------
// Fundamental Dimensions
//----------------------------
gearModule       = 2.5;    // Module (pitch) for all gears
pressureAngle    = 20;     // Pressure angle in degrees
gearClearance    = 0.5;    // Clearance for meshing
gearWidth        = 16;     // Axial width of each gear
gearSpacing      = 30;     // Distance used as “stacking” offset
shaftLength      = 350;    // Overall length for the shafts

//----------------------------
// Shaft Diameters
//----------------------------
inputShaftDia   = 25;
layshaftDia     = 30;
outputShaftDia  = 28;
idlerShaftDia   = 20;  // For the reverse idler

//----------------------------
// Synchronizer Dimensions
//----------------------------
synchroWidth    = 22;
synchroDia      = 55;
dogHeight       = 5;

//----------------------------
// Gear Tooth Counts
// (Set so that total ratios match the target specs.)
//----------------------------
layshaftDriveTeeth  = 20;
inputDriveTeeth     = 32;

layshaftFirstTeeth  = 22;
outputFirstTeeth    = 71; // ratio ~3.23:1

layshaftSecondTeeth = 28;
outputSecondTeeth   = 59; // ratio ~2.11:1

layshaftThirdTeeth  = 33;
outputThirdTeeth    = 47; // ratio ~1.42:1

inputFourthTeeth    = 40;
outputFourthTeeth   = 40; // ratio ~1.00:1

layshaftFifthTeeth  = 40;
inputFifthTeeth     = 32; // ratio ~0.81:1

layshaftSixthTeeth  = 45;
inputSixthTeeth     = 28; // ratio ~0.62:1

layshaftReverseTeeth = 18;
idlerReverseTeeth    = 20;
outputReverseTeeth   = 56; // ratio ~3.8:1

//----------------------------
// Shaft Positions
// Compute offset so the input and layshaft gears mesh properly,
// then compute the output shaft offset similarly
//----------------------------

// Utility: pitch diameter from tooth count
function pitch_diameter(t) = t * gearModule;

// Distance between centers for the input-layshaft gears:
layshaftOffset = (pitch_diameter(inputDriveTeeth) + pitch_diameter(layshaftDriveTeeth)) / 2 
                 + 2;  // 2 mm of extra clearance to prevent overlap

// The input shaft is at (0,0,0). Put the layshaft on the +X axis.
inputShaftPos  = [0, 0, 0];
layshaftPos    = [layshaftOffset, 0, 0];

// For the output shaft, we do approximate geometry so that
// first gear on the layshaft meshes with first gear on the output.
outputOffsetX = layshaftOffset / 2;
outputOffsetY = -sqrt(
    pow((pitch_diameter(layshaftFirstTeeth) + pitch_diameter(outputFirstTeeth)) / 2, 2) 
    - pow(layshaftOffset / 2, 2)
);
outputShaftPos = [outputOffsetX, outputOffsetY, 0];

// Reverse idler position
// Adjust as needed to avoid collisions and to mesh the reverse path
idlerPos = [
    layshaftOffset * 0.75,   // somewhat arbitrary
    outputOffsetY / 2, 
    -5 * gearSpacing
];

//----------------------------
// Utility Functions
//----------------------------

// Calculate gear ratio from two gears
function calc_ratio(driver_teeth, driven_teeth) = driven_teeth / driver_teeth;

// Generate gear (with optional hub & dog teeth) using MCAD involute gears
module gear_with_hub(teeth, width, hole_dia, hub_dia, hub_width) {
    difference() {
        union() {
            // The MCAD gear
            gear(
                number_of_teeth    = teeth,
                circular_pitch     = gearModule * PI,
                pressure_angle     = pressureAngle,
                clearance         = gearClearance,
                gear_thickness     = width,
                rim_thickness      = width,
                hub_thickness      = hub_width,
                hub_diameter       = hub_dia
            );
            
            // Example dog lugs for synchronizer (simple cubes)
            // Only add them if the gear is large enough
            if (hub_dia > 0 && teeth > 30) {
                for (i = [0 : 5]) {
                    rotate([0, 0, i * 60])
                    translate([hub_dia / 2 + 5, 0, width / 2])
                    cube([8, 4, dogHeight], center=true);
                }
            }
        }
        // Center hole (bore for the shaft)
        translate([0, 0, -1])
        cylinder(h = width + hub_width + 2, d = hole_dia);
    }
}

// A simplified synchronizer hub
module synchronizer(shaft_dia) {
    color(color_synchro) {
        difference() {
            union() {
                // Outer cylinder
                cylinder(h = synchroWidth, d = synchroDia);

                // Selector fork groove (via rotate_extrude)
                translate([0, 0, synchroWidth / 2])
                rotate_extrude() {
                    translate([synchroDia/2 + 5, 0, 0])
                    circle(d=8);
                }

                // Inner + outer dog teeth
                for (i = [0 : 5]) {
                    // inner set
                    rotate([0, 0, i * 60])
                    translate([synchroDia/2 - 8, 0, 0])
                    cube([12, 5, dogHeight]);
                    // outer set
                    rotate([0, 0, i * 60])
                    translate([synchroDia/2 - 8, 0, synchroWidth - dogHeight])
                    cube([12, 5, dogHeight]);
                }
            }
            // Bore for the shaft
            translate([0, 0, -1])
            cylinder(h = synchroWidth + 2, d = shaft_dia);
        }
    }
}

//----------------------------
// Shaft Modules
//----------------------------
module input_shaft() {
    translate(inputShaftPos) {
        // Main input shaft
        color(color_shaft)
        cylinder(h=shaftLength, d=inputShaftDia, center=true);
        
        // Input drive gear (fixed)
        translate([0, 0, 5 * gearSpacing])
        color(color_input_gear)
        gear_with_hub(
            teeth       = inputDriveTeeth, 
            width       = gearWidth,
            hole_dia    = inputShaftDia,
            hub_dia     = inputShaftDia + 10, 
            hub_width   = 10
        );
        
        // 5th gear (free spinning on shaft)
        translate([0, 0, -2 * gearSpacing])
        color(color_input_gear)
        gear_with_hub(
            teeth       = inputFifthTeeth, 
            width       = gearWidth, 
            hole_dia    = inputShaftDia + 2,
            hub_dia     = inputShaftDia + 15, 
            hub_width   = 8
        );
        
        // 6th gear (free spinning)
        translate([0, 0, -4 * gearSpacing])
        color(color_input_gear)
        gear_with_hub(
            teeth       = inputSixthTeeth, 
            width       = gearWidth, 
            hole_dia    = inputShaftDia + 2,
            hub_dia     = inputShaftDia + 15, 
            hub_width   = 8
        );
        
        // 4th gear direct drive collar (fixed to shaft)
        translate([0, 0, 0])
        color(color_input_gear)
        gear_with_hub(
            teeth       = inputFourthTeeth, 
            width       = gearWidth, 
            hole_dia    = inputShaftDia,
            hub_dia     = inputShaftDia + 10, 
            hub_width   = 5
        );
    }
}

module layshaft() {
    translate(layshaftPos) {
        // Layshaft geometry
        color(color_layshaft)
        cylinder(h=shaftLength, d=layshaftDia, center=true);

        // Drive gear (meshes w/ input drive)
        translate([0, 0, 5 * gearSpacing])
        color(color_layshaft_gear)
        gear_with_hub(
            teeth       = layshaftDriveTeeth, 
            width       = gearWidth, 
            hole_dia    = layshaftDia,
            hub_dia     = layshaftDia + 15, 
            hub_width   = 10
        );
        
        // 1st, 2nd, 3rd, 5th, 6th, Reverse drive gears
        // The Z positions are stacked with gearSpacing
        translate([0, 0, 3 * gearSpacing])
        color(color_layshaft_gear)
        gear_with_hub(
            teeth       = layshaftFirstTeeth, 
            width       = gearWidth, 
            hole_dia    = layshaftDia,
            hub_dia     = layshaftDia + 15, 
            hub_width   = 8
        );

        translate([0, 0, 1 * gearSpacing])
        color(color_layshaft_gear)
        gear_with_hub(
            teeth       = layshaftSecondTeeth, 
            width       = gearWidth, 
            hole_dia    = layshaftDia,
            hub_dia     = layshaftDia + 15, 
            hub_width   = 8
        );

        translate([0, 0, -1 * gearSpacing])
        color(color_layshaft_gear)
        gear_with_hub(
            teeth       = layshaftThirdTeeth, 
            width       = gearWidth, 
            hole_dia    = layshaftDia,
            hub_dia     = layshaftDia + 15, 
            hub_width   = 8
        );

        translate([0, 0, -2 * gearSpacing])
        color(color_layshaft_gear)
        gear_with_hub(
            teeth       = layshaftFifthTeeth, 
            width       = gearWidth, 
            hole_dia    = layshaftDia,
            hub_dia     = layshaftDia + 15, 
            hub_width   = 8
        );

        translate([0, 0, -4 * gearSpacing])
        color(color_layshaft_gear)
        gear_with_hub(
            teeth       = layshaftSixthTeeth, 
            width       = gearWidth, 
            hole_dia    = layshaftDia,
            hub_dia     = layshaftDia + 15, 
            hub_width   = 8
        );

        translate([0, 0, -5 * gearSpacing])
        color(color_layshaft_gear)
        gear_with_hub(
            teeth       = layshaftReverseTeeth, 
            width       = gearWidth, 
            hole_dia    = layshaftDia,
            hub_dia     = layshaftDia + 15, 
            hub_width   = 8
        );
    }
}

module output_shaft() {
    translate(outputShaftPos) {
        // Output shaft
        color(color_shaft)
        cylinder(h=shaftLength, d=outputShaftDia, center=true);

        // 1st gear (free spinning)
        translate([0, 0, 3 * gearSpacing])
        color(color_output_gear)
        gear_with_hub(
            teeth     = outputFirstTeeth, 
            width     = gearWidth, 
            hole_dia  = outputShaftDia + 2,
            hub_dia   = outputShaftDia + 18, 
            hub_width = 10
        );

        // 2nd gear
        translate([0, 0, 1 * gearSpacing])
        color(color_output_gear)
        gear_with_hub(
            teeth     = outputSecondTeeth, 
            width     = gearWidth, 
            hole_dia  = outputShaftDia + 2,
            hub_dia   = outputShaftDia + 18, 
            hub_width = 10
        );

        // 3rd gear
        translate([0, 0, -1 * gearSpacing])
        color(color_output_gear)
        gear_with_hub(
            teeth     = outputThirdTeeth, 
            width     = gearWidth, 
            hole_dia  = outputShaftDia + 2,
            hub_dia   = outputShaftDia + 18, 
            hub_width = 10
        );

        // 4th gear collar (part of output shaft)
        translate([0, 0, 0])
        color(color_output_gear)
        gear_with_hub(
            teeth     = outputFourthTeeth, 
            width     = gearWidth, 
            hole_dia  = outputShaftDia,
            hub_dia   = outputShaftDia + 10, 
            hub_width = 5
        );

        // Synchronizer 1-2
        translate([0, 0, 2 * gearSpacing])
        synchronizer(outputShaftDia);

        // Synchronizer 3-4
        translate([0, 0, -0.5 * gearSpacing])
        synchronizer(outputShaftDia);

        // Synchronizer 5-6
        translate([0, 0, -3 * gearSpacing])
        synchronizer(outputShaftDia);

        // Reverse gear (free spinning)
        translate([0, 0, -5 * gearSpacing])
        color(color_output_gear)
        gear_with_hub(
            teeth     = outputReverseTeeth, 
            width     = gearWidth, 
            hole_dia  = outputShaftDia + 2,
            hub_dia   = outputShaftDia + 18, 
            hub_width = 10
        );
        
        // Output flange (just a simple stub)
        translate([0, 0, -shaftLength/2 + 20])
        color(color_shaft) {
            cylinder(h=15, d=outputShaftDia+10);
            cylinder(h=25, d=outputShaftDia);
        }
    }
}

// Reverse idler gear and its small shaft
module reverse_idler() {
    translate(idlerPos) {
        color(color_shaft)
        cylinder(h=60, d=idlerShaftDia, center=true);

        color(color_reverse_gear)
        gear_with_hub(
            teeth     = idlerReverseTeeth,
            width     = gearWidth,
            hole_dia  = idlerShaftDia + 1,
            hub_dia   = idlerShaftDia + 10,
            hub_width = 5
        );
    }
}

//----------------------------
// Selector Rods & Shift Forks
//----------------------------
module shift_fork(forkLength) {
    color(color_shift_fork) {
        difference() {
            union() {
                // Main circular block
                cylinder(h=8, d=12, center=true);
                // Horizontal arm
                translate([forkLength/2, 0, 0])
                rotate([0, 90, 0])
                cylinder(h=forkLength, d=8, center=true);
                // Fork ends
                translate([forkLength, 0, 0])
                cylinder(h=12, d=20, center=true);
            }
            // Hole for selector rod
            rotate([0, 90, 0])
            cylinder(h=forkLength*2, d=6, center=true);
        }
    }
}

module selector_rods() {
    color(color_selector) {
        // For clarity, offset rods to the “side” near the output shaft
        // 1-2 selector rod
        translate([outputShaftPos[0]-20, outputShaftPos[1]+30,  2*gearSpacing])
        rotate([0, 90, 0])
        cylinder(h=200, d=6, center=true);

        // 3-4 selector rod
        translate([outputShaftPos[0]-20, outputShaftPos[1]+30, -0.5*gearSpacing])
        rotate([0, 90, 0])
        cylinder(h=200, d=6, center=true);

        // 5-6 selector rod
        translate([outputShaftPos[0]-20, outputShaftPos[1]+30, -3*gearSpacing])
        rotate([0, 90, 0])
        cylinder(h=200, d=6, center=true);

        // Reverse rod
        translate([outputShaftPos[0]-20, outputShaftPos[1]+30, -5*gearSpacing])
        rotate([0, 90, 0])
        cylinder(h=200, d=6, center=true);
    }
    
    // Attach forks
    translate([outputShaftPos[0], outputShaftPos[1]+30, 2*gearSpacing])
    shift_fork(30);

    translate([outputShaftPos[0], outputShaftPos[1]+30, -0.5*gearSpacing])
    shift_fork(30);

    translate([outputShaftPos[0], outputShaftPos[1]+30, -3*gearSpacing])
    shift_fork(30);
}

//----------------------------
// Transmission Case (Optional)
//----------------------------
module transmission_case() {
    color(color_case, 0.3) {
        difference() {
            // Outer Minkowski box “shell”
            minkowski() {
                cube([200, 180, shaftLength + 20], center=true);
                sphere(r=10);
            }
            // Hollow out the inside
            cube([190, 170, shaftLength + 30], center=true);
            
            // Output shaft hole
            translate(outputShaftPos)
            rotate([0, 90, 0])
            cylinder(h=100, d=40, center=true);
            
            // Input shaft hole
            translate(inputShaftPos)
            rotate([0, 90, 0])
            cylinder(h=100, d=40, center=true);
        }
    }
}

module gearbox() {
    if (cutaway_view) {
        difference() {
            union() {
                input_shaft();
                layshaft();
                output_shaft();
                reverse_idler();
                selector_rods();
            }
            // Cut half the model away
            translate([-150, 0, 0])
            cube([300, 300, 300], center=true);
        }
    } else {
        // Full assembly
        input_shaft();
        layshaft();
        output_shaft();
        reverse_idler();
        selector_rods();
        if (show_case) {
            transmission_case();
        }
    }
}

gearbox();

echo("1st gear ratio = ", calc_ratio(layshaftFirstTeeth * layshaftDriveTeeth, outputFirstTeeth * inputDriveTeeth));
echo("2nd gear ratio = ", calc_ratio(layshaftSecondTeeth * layshaftDriveTeeth, outputSecondTeeth * inputDriveTeeth));
echo("3rd gear ratio = ", calc_ratio(layshaftThirdTeeth * layshaftDriveTeeth, outputThirdTeeth * inputDriveTeeth));
echo("4th gear ratio = 1.0 (direct drive)");
echo("5th gear ratio = ", calc_ratio(layshaftFifthTeeth, inputFifthTeeth));
echo("6th gear ratio = ", calc_ratio(layshaftSixthTeeth, inputSixthTeeth));
echo("Reverse ratio  = ", calc_ratio(layshaftReverseTeeth * layshaftDriveTeeth, outputReverseTeeth * inputDriveTeeth));
