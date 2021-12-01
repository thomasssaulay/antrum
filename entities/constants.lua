DEBUG = false
PATHFINDING_DEBUG = false
QUERY_DEBUG = true

GLOBAL_SCALE = 2
TILE_SIZE_X = 32
TILE_SIZE_Y = 32
MAP_SIZE_X = 64
MAP_SIZE_Y = 64
CHANCE_BEDROCK = 0.2
NEAR_BASE_RADIUS = math.floor((MAP_SIZE_X * MAP_SIZE_Y) / 260)

CHANCE_NEWWALKER = 0.10
CHANCE_DESTROWALKER = 0.05
CHANCE_CHANGEDIR = 0.3
ROOT_CHANCE_NEWWALKER = 0.05
ROOT_CHANCE_DESTROWALKER = 0.1
ROOT_CHANCE_CHANGEDIR = 0.05
MAX_WALKER = 99
MAX_HOLES = math.floor((MAP_SIZE_X * MAP_SIZE_Y) / 2)
MAX_ROOT_LENGTH = math.floor(MAP_SIZE_X / 3)
MAX_ROOTS = math.floor(MAP_SIZE_X / 6)
N_BEETLES = 6
N_ITEMS = 6

NEIGHBORS = {
	-MAP_SIZE_X - 1,
	-MAP_SIZE_X,
	-MAP_SIZE_X + 1,
	-1,
	1,
	MAP_SIZE_X - 1,
	MAP_SIZE_X,
	MAP_SIZE_X + 1
}
NEIGHBORS_4 = {
	-MAP_SIZE_X,
	-1,
	1,
	MAP_SIZE_X
}

GAMEPAD_THRESHOLD = 0.08
STUN_TIME = 10
PARTICLE_LIFETIME = 5
TIME_LIMIT = 300
DISTANCE_ATTENUATION_AUDIO = 64

MUSIC_ON = true
SOUND_ON = true

SHADER_LIGHT = [[
#define NUM_LIGHTS 32
struct Light {
vec2 position;
vec3 diffuse;
float power;
};
extern Light lights[NUM_LIGHTS];
extern int num_lights;
extern vec2 screen;
const float constant = 1.0;
const float linear = 0.09;
const float quadratic = 0.032;
vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords){
vec4 pixel = Texel(image, uvs);
vec2 norm_screen = screen_coords / screen;
vec3 diffuse = vec3(0);
for (int i = 0; i < num_lights; i++) {
	Light light = lights[i];
	vec2 norm_pos = light.position / screen;

	float distance = length(norm_pos - norm_screen) * light.power;
	float attenuation = 1.0 / (constant + linear * distance + quadratic * (distance * distance));
	diffuse += light.diffuse * attenuation;
}
diffuse = clamp(diffuse, 0.0, 1.0);
return pixel * vec4(diffuse, 1.0);
}
]]