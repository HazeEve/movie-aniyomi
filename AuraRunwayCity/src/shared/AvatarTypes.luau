--!nonstrict
-- Maps Roblox AssetTypeIds to how they are worn on a HumanoidDescription.
local T = {}

-- kind: "acc" (accessory), "prop" (HumanoidDescription property), "anim"
T.ById = {
	[8] = { Name = "Hat", Kind = "acc", Acc = "Hat" },
	[41] = { Name = "Hair", Kind = "acc", Acc = "Hair" },
	[42] = { Name = "Face Accessory", Kind = "acc", Acc = "Face" },
	[43] = { Name = "Neck", Kind = "acc", Acc = "Neck" },
	[44] = { Name = "Shoulder", Kind = "acc", Acc = "Shoulder" },
	[45] = { Name = "Front", Kind = "acc", Acc = "Front" },
	[46] = { Name = "Back", Kind = "acc", Acc = "Back" },
	[47] = { Name = "Waist", Kind = "acc", Acc = "Waist" },
	[76] = { Name = "Eyebrow", Kind = "acc", Acc = "Eyebrow" },
	[77] = { Name = "Eyelash", Kind = "acc", Acc = "Eyelash" },
	[64] = { Name = "T-Shirt (3D)", Kind = "acc", Acc = "TShirt", Layered = true, Order = 9 },
	[65] = { Name = "Shirt (3D)", Kind = "acc", Acc = "Shirt", Layered = true, Order = 10 },
	[66] = { Name = "Pants (3D)", Kind = "acc", Acc = "Pants", Layered = true, Order = 5 },
	[67] = { Name = "Jacket", Kind = "acc", Acc = "Jacket", Layered = true, Order = 12 },
	[68] = { Name = "Sweater", Kind = "acc", Acc = "Sweater", Layered = true, Order = 11 },
	[69] = { Name = "Shorts", Kind = "acc", Acc = "Shorts", Layered = true, Order = 6 },
	[70] = { Name = "Left Shoe", Kind = "acc", Acc = "LeftShoe", Layered = true, Order = 3 },
	[71] = { Name = "Right Shoe", Kind = "acc", Acc = "RightShoe", Layered = true, Order = 3 },
	[72] = { Name = "Dress / Skirt", Kind = "acc", Acc = "DressSkirt", Layered = true, Order = 8 },
	[11] = { Name = "Shirt", Kind = "prop", Prop = "Shirt" },
	[12] = { Name = "Pants", Kind = "prop", Prop = "Pants" },
	[2] = { Name = "T-Shirt", Kind = "prop", Prop = "GraphicTShirt" },
	[18] = { Name = "Face", Kind = "prop", Prop = "Face" },
	[17] = { Name = "Head", Kind = "prop", Prop = "Head" },
	[79] = { Name = "Dynamic Head", Kind = "prop", Prop = "Head" },
	[27] = { Name = "Torso", Kind = "prop", Prop = "Torso" },
	[28] = { Name = "Right Arm", Kind = "prop", Prop = "RightArm" },
	[29] = { Name = "Left Arm", Kind = "prop", Prop = "LeftArm" },
	[30] = { Name = "Left Leg", Kind = "prop", Prop = "LeftLeg" },
	[31] = { Name = "Right Leg", Kind = "prop", Prop = "RightLeg" },
	[48] = { Name = "Climb Animation", Kind = "anim", Prop = "ClimbAnimation" },
	[50] = { Name = "Fall Animation", Kind = "anim", Prop = "FallAnimation" },
	[51] = { Name = "Idle Animation", Kind = "anim", Prop = "IdleAnimation" },
	[52] = { Name = "Jump Animation", Kind = "anim", Prop = "JumpAnimation" },
	[53] = { Name = "Run Animation", Kind = "anim", Prop = "RunAnimation" },
	[54] = { Name = "Swim Animation", Kind = "anim", Prop = "SwimAnimation" },
	[55] = { Name = "Walk Animation", Kind = "anim", Prop = "WalkAnimation" },
	[56] = { Name = "Pose Animation", Kind = "anim", Prop = "MoodAnimation" },
}

-- HumanoidDescription properties that hold one asset id each
T.SingleProps = {
	"Shirt", "Pants", "GraphicTShirt", "Face", "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg",
	"ClimbAnimation", "FallAnimation", "IdleAnimation", "JumpAnimation", "RunAnimation", "SwimAnimation",
	"WalkAnimation", "MoodAnimation",
}

T.PropTypeName = {
	Shirt = "Shirt", Pants = "Pants", GraphicTShirt = "T-Shirt", Face = "Face", Head = "Head",
	Torso = "Torso", LeftArm = "Left Arm", RightArm = "Right Arm", LeftLeg = "Left Leg", RightLeg = "Right Leg",
	ClimbAnimation = "Animation", FallAnimation = "Animation", IdleAnimation = "Animation",
	JumpAnimation = "Animation", RunAnimation = "Animation", SwimAnimation = "Animation",
	WalkAnimation = "Animation", MoodAnimation = "Animation",
}

T.ScaleLimits = {
	HeightScale = { 0.9, 1.05 },
	WidthScale = { 0.7, 1.0 },
	DepthScale = { 0.7, 1.0 },
	HeadScale = { 0.95, 1.0 },
	BodyTypeScale = { 0, 1 },
	ProportionScale = { 0, 1 },
}

T.SkinTones = {
	"FDE7D6", "F6D2B8", "EBC09F", "D9A77F", "C68B63", "A96E4B", "8A5537", "6B3F28", "4E2C1C",
	"F4D9E4", "DCCFF2", "FFFFFF",
}

return T
