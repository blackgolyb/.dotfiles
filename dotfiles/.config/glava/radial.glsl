
/* center radius (pixels) */
#define C_RADIUS 337
/* center line thickness (pixels) */
#define C_LINE 0
/* outline color */
#define OUTLINE #cc3333
/* number of bars (use even values for best results) */
#define NBARS 180
/* width (in pixels) of each bar*/
#define BAR_WIDTH 10
/* outline color */
#define BAR_OUTLINE OUTLINE
/* outline width (in pixels, set to 0 to disable outline drawing) */
#define BAR_OUTLINE_WIDTH 0
/* Amplify magnitude of the results each bar displays */
#define AMPLIFY 500
/* Bar color */ 
// (#743844 * (40/(d+1))) + (#351017 * (1 - 40/(d+1)))
//#define COLOR  (#c33844 * (1 - d/60)) + (#351017 * (d/100))
// #define COLOR #743844
#define GRADIENT 70
/* Цвет полосы. По умолчанию это градиент. */
#define COLOR mix(#c33844, #351017, clamp(d / GRADIENT, 0, 1))
/* Angle (in radians) for how much to rotate the visualizer */
#define ROTATE (PI / 2)
/* Whether to switch left/right audio buffers */
#define INVERT 0
/* Aliasing factors. Higher values mean more defined and jagged lines.
   Note: aliasing does not have a notable impact on performance, but requires
   `xroot` transparency to be enabled since it relies on alpha blending with
   the background. */
#define BAR_ALIAS_FACTOR 0.5
#define C_ALIAS_FACTOR 1.8
/* Offset (Y) of the visualization */
#define CENTER_OFFSET_Y -199
/* Offset (X) of the visualization */
#define CENTER_OFFSET_X 38

/* Gravity step, override from `smooth_parameters.glsl` */
#request setgravitystep 7.0
// #request setgravitystep 4

/* Smoothing factor, override from `smooth_parameters.glsl` */
#request setsmoothfactor 0.025
