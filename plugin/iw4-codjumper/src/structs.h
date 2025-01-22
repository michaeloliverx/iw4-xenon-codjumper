typedef unsigned int uint32_t;

typedef float vec3[3];

struct playerState_s
{
	char padding1[0xC];
	uint32_t pm_flags;
	char padding2[0xC];
	vec3 origin;
	vec3 velocity;
	char padding3[0xD8];
	vec3 viewAngles;
	char padding4[0x3068];
};

static_assert(sizeof(playerState_s) == 0x3180, "");

struct gclient_s
{
	playerState_s ps;
	char padding1[0x2A0];
	int mFlags;
	char padding2[0x2DC];
};

static_assert(sizeof(gclient_s) == 0x3700, "");

struct entityState_s
{
	int number;
	char padding1[0x84];
	int index;
	char padding2[0x70];
};

static_assert(sizeof(entityState_s) == 0xFC, "");

struct entityShared_t
{
	int clientMask;
	bool linked;
	char bmodel;
	char svFlags;
	bool inuse;
	vec3 mins;
	vec3 maxs;
	int contents;
	vec3 absmin;
	vec3 absmax;
	vec3 currentOrigin;
	vec3 currentAngles;
	int ownerNum;
	int eventTime;
};

static_assert(sizeof(entityShared_t) == 0x5C, "");

struct gentity_s
{
	entityState_s state;
	entityShared_t r;
	gclient_s *client;
	char padding1[0x28];
	int flags;
	char padding2[0xF8];
};

static_assert(sizeof(gentity_s) == 0x280, "");

/* 4480 */
struct Bounds
{
	float midPoint[3];
	float halfSize[3];
};

/* 4756 */
struct WeaponDef;
struct WeaponCompleteDef;

/* 5025 */
struct weaponParms
{
	float forward[3];
	float right[3];
	float up[3];
	float muzzleTrace[3];
	float gunForward[3];
	unsigned int weaponIndex;
	const int *weapDef;
	const int *weapCompleteDef;
};
