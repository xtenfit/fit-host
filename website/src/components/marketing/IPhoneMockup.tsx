import Image from "next/image";

export interface IPhoneMockupProps {
  src: string;
  alt: string;
  caption?: string;
  badge?: string;
  size?: "sm" | "md" | "lg";
  glowColor?: "green" | "blue" | "cyan" | "none";
  finish?: "black" | "natural" | "silver";
  priority?: boolean;
  aspectRatio?: "auto" | "37/76" | "standard" | "tall" | string;
  className?: string;
}

// Map of authentic screenshot aspect ratios (width / height) so every screen UI
// renders completely uncropped and properly visible without cutting off any text or buttons
const KNOWN_SCREENSHOT_RATIOS: Record<string, string> = {
  "/images/screenshots/home.png": "1000/1688",
  "/images/screenshots/diary.png": "1000/1688",
  "/images/screenshots/nutrition.png": "1048/1740",
  "/images/screenshots/workouts.png": "1048/1740",
  "/images/screenshots/progress.png": "1048/1740",
  "/images/screenshots/alarms.png": "720/1480",
  "/images/screenshots/summary.png": "720/1480",
};

export default function IPhoneMockup({
  src,
  alt,
  caption,
  badge,
  size = "md",
  glowColor = "green",
  finish = "black",
  priority = false,
  aspectRatio = "auto",
  className = "",
}: IPhoneMockupProps) {
  // Constrained responsive width variants — height adapts dynamically to screen ratio
  const sizeClasses = {
    sm: "max-w-[230px] sm:max-w-[250px]",
    md: "max-w-[280px] sm:max-w-[305px] md:max-w-[325px]",
    lg: "max-w-[310px] sm:max-w-[340px] md:max-w-[360px]",
  };

  // Determine aspect ratio for phone mockup — defaults to reference mobile phone ratio (aspect-[37/76])
  // to ensure a uniform, tall, sleek, and authentic smartphone silhouette across all sections
  let currentRatioClass = "aspect-[37/76]";
  if (aspectRatio && aspectRatio !== "auto") {
    currentRatioClass =
      aspectRatio === "tall" || aspectRatio === "37/76"
        ? "aspect-[37/76]"
        : aspectRatio === "standard"
        ? "aspect-[37/76]"
        : `aspect-[${aspectRatio}]`;
  }

  // Hardware finish variants (Aerospace PVD Titanium / Polished Stainless Steel)
  // Engineered with multi-stop anisotropic metallic gradients, specular chamfer highlights, and physical reflections
  const finishStyles = {
    black: {
      chassisRim:
        "bg-gradient-to-br from-zinc-400 via-zinc-700 to-zinc-950 shadow-[0_0_0_1px_rgba(255,255,255,0.20),inset_0_1px_1.5px_rgba(255,255,255,0.40),inset_0_-1px_2px_rgba(0,0,0,0.9),0_25px_60px_-12px_rgba(0,0,0,0.9),0_40px_90px_-20px_rgba(0,0,0,0.95)]",
      chamferBevel:
        "bg-gradient-to-b from-[#18181b] to-[#09090b] shadow-[inset_0_1px_1.5px_rgba(0,0,0,0.95),0_0.5px_0_rgba(255,255,255,0.08)]",
      buttons:
        "from-zinc-300 via-zinc-500 to-zinc-700 border-white/30 shadow-[-2px_0_4px_rgba(0,0,0,0.6)]",
      buttonPower:
        "from-zinc-300 via-zinc-500 to-zinc-700 border-white/30 shadow-[2px_0_4px_rgba(0,0,0,0.6)]",
      antenna: "bg-[#27272a] shadow-inner border-y border-black/40",
      speakerMesh: "bg-[#0a0a0c] border-white/10",
    },
    natural: {
      chassisRim:
        "bg-gradient-to-br from-[#d4ccbe] via-[#9e9587] to-[#3a3731] shadow-[0_0_0_1px_rgba(245,240,230,0.30),inset_0_1px_1.5px_rgba(255,255,255,0.50),inset_0_-1px_2px_rgba(0,0,0,0.85),0_25px_60px_-12px_rgba(0,0,0,0.9),0_40px_90px_-20px_rgba(0,0,0,0.95)]",
      chamferBevel:
        "bg-gradient-to-b from-[#221f1a] to-[#0e0c0a] shadow-[inset_0_1px_1.5px_rgba(0,0,0,0.95),0_0.5px_0_rgba(255,240,220,0.10)]",
      buttons:
        "from-[#e2d8c9] via-[#9e9587] to-[#5c564c] border-[#f5eee3]/40 shadow-[-2px_0_4px_rgba(0,0,0,0.6)]",
      buttonPower:
        "from-[#e2d8c9] via-[#9e9587] to-[#5c564c] border-[#f5eee3]/40 shadow-[2px_0_4px_rgba(0,0,0,0.6)]",
      antenna: "bg-[#453f36] shadow-inner border-y border-black/40",
      speakerMesh: "bg-[#14120e] border-[#b8af9f]/20",
    },
    silver: {
      chassisRim:
        "bg-gradient-to-br from-zinc-100 via-zinc-400 to-zinc-800 shadow-[0_0_0_1px_rgba(255,255,255,0.5),inset_0_1px_1.5px_rgba(255,255,255,0.7),inset_0_-1px_2px_rgba(0,0,0,0.8),0_25px_60px_-12px_rgba(0,0,0,0.9),0_40px_90px_-20px_rgba(0,0,0,0.95)]",
      chamferBevel:
        "bg-gradient-to-b from-[#27272a] to-[#0f1115] shadow-[inset_0_1px_1.5px_rgba(0,0,0,0.95),0_0.5px_0_rgba(255,255,255,0.18)]",
      buttons:
        "from-white via-zinc-200 to-zinc-500 border-white/60 shadow-[-2px_0_4px_rgba(0,0,0,0.6)]",
      buttonPower:
        "from-white via-zinc-200 to-zinc-500 border-white/60 shadow-[2px_0_4px_rgba(0,0,0,0.6)]",
      antenna: "bg-[#3f3f46] shadow-inner border-y border-black/40",
      speakerMesh: "bg-[#111215] border-white/20",
    },
  };

  // Ambient aura styles (Fit Host electric brand lighting)
  const glowStyles = {
    green:
      "before:absolute before:-inset-5 before:-z-10 before:rounded-[56px] before:bg-brand-green/20 before:blur-2xl before:transition-all hover:before:bg-brand-green/35",
    blue:
      "before:absolute before:-inset-5 before:-z-10 before:rounded-[56px] before:bg-brand-blue/20 before:blur-2xl before:transition-all hover:before:bg-brand-blue/35",
    cyan:
      "before:absolute before:-inset-5 before:-z-10 before:rounded-[56px] before:bg-brand-cyan/20 before:blur-2xl before:transition-all hover:before:bg-brand-cyan/35",
    none: "",
  };

  const currentFinish = finishStyles[finish] || finishStyles.black;

  return (
    <div className={`flex flex-col items-center w-full select-none ${className}`}>
      {/* Outer wrapper with responsive max-width and atmospheric back-glow */}
      <div
        className={`relative w-full ${sizeClasses[size]} transition-all duration-300 ease-out hover:scale-[1.018] ${glowStyles[glowColor]}`}
      >
        {/* Physical Hardware Buttons (Protruding CNC-Machined Titanium) */}
        {/* Action Button (Top Left: 11.5% from top, 3.4% height) */}
        <div
          className={`absolute -left-[3px] top-[11.5%] w-[3px] h-[3.4%] bg-gradient-to-r ${currentFinish.buttons} rounded-l-[2px] border-y border-l`}
          aria-hidden="true"
        />
        {/* Volume Up Button (Left: 17.5% from top, 5.8% height) */}
        <div
          className={`absolute -left-[3px] top-[17.5%] w-[3px] h-[5.8%] bg-gradient-to-r ${currentFinish.buttons} rounded-l-[2px] border-y border-l`}
          aria-hidden="true"
        />
        {/* Volume Down Button (Left: 25% from top, 5.8% height) */}
        <div
          className={`absolute -left-[3px] top-[25%] w-[3px] h-[5.8%] bg-gradient-to-r ${currentFinish.buttons} rounded-l-[2px] border-y border-l`}
          aria-hidden="true"
        />
        {/* Side / Power Button (Right: 19% from top, 8.8% height) */}
        <div
          className={`absolute -right-[3px] top-[19%] w-[3px] h-[8.8%] bg-gradient-to-l ${currentFinish.buttonPower} rounded-r-[2px] border-y border-r`}
          aria-hidden="true"
        />

        {/* Antenna Bands (Laser-Cut PVD Insulating Joints) */}
        <div className={`absolute -left-[1.5px] top-[8.5%] w-[2.5px] h-[3.5px] ${currentFinish.antenna}`} aria-hidden="true" />
        <div className={`absolute -left-[1.5px] bottom-[8.5%] w-[2.5px] h-[3.5px] ${currentFinish.antenna}`} aria-hidden="true" />
        <div className={`absolute -right-[1.5px] top-[8.5%] w-[2.5px] h-[3.5px] ${currentFinish.antenna}`} aria-hidden="true" />
        <div className={`absolute -right-[1.5px] bottom-[8.5%] w-[2.5px] h-[3.5px] ${currentFinish.antenna}`} aria-hidden="true" />

        {/* Micro Acoustic Ear Speaker Hairline Seam at Top Chassis Outer Seam */}
        <div
          className={`absolute top-[1.5px] left-1/2 -translate-x-1/2 z-30 w-11 sm:w-14 h-[1.5px] rounded-full ${currentFinish.speakerMesh} shadow-[inset_0_0.5px_1px_rgba(0,0,0,0.95)] flex items-center justify-center`}
          aria-hidden="true"
        >
          <div className="w-7 sm:w-8 h-[0.75px] rounded-full bg-zinc-800" />
        </div>

        {/* Outer Titanium Chassis: Ultra-Thin Precision Brushed Metal with Specular Chamfer */}
        {/* Bezel-less design: ultra-slim uniform 2.5px-3px outer rim */}
        <div
          className={`relative w-full p-[2.5px] sm:p-[3px] rounded-[38px] sm:rounded-[42px] md:rounded-[46px] ${currentFinish.chassisRim}`}
        >
          {/* Inner Recessed Bezel Bed (Razor-thin, 100% symmetric 2px bezel) */}
          <div
            className={`w-full p-[1.5px] sm:p-[2px] rounded-[36px] sm:rounded-[40px] md:rounded-[44px] ${currentFinish.chamferBevel}`}
          >
            {/* Screen Glass Area — Modern Bezel-Less Edge-to-Edge Display with Exact 37/76 Mobile Ratio */}
            <div
              className={`relative w-full overflow-hidden rounded-[34px] sm:rounded-[38px] md:rounded-[42px] bg-[#0B0D11] shadow-[inset_0_0_0_1px_rgba(255,255,255,0.06),inset_0_1.5px_3px_rgba(0,0,0,0.85)] ${currentRatioClass}`}
            >
              {/* Actual Fit Host Flutter Mobile UI Screenshot — Symmetric & Completely Uncropped */}
              <div className="relative w-full h-full flex items-center justify-center">
                <Image
                  src={src}
                  alt={alt}
                  fill
                  sizes="(max-width: 640px) 250px, (max-width: 768px) 325px, 360px"
                  priority={priority}
                  className="object-contain select-none pointer-events-none"
                  unoptimized
                />
              </div>

              {/* Specular Diagonal Optical Glass Reflection Sheen */}
              <div
                className="pointer-events-none absolute inset-0 z-10"
                style={{
                  background:
                    "linear-gradient(125deg, rgba(255,255,255,0.13) 0%, rgba(255,255,255,0.02) 24%, transparent 45%, transparent 70%, rgba(255,255,255,0.03) 85%, rgba(255,255,255,0.08) 100%)",
                }}
                aria-hidden="true"
              />

              {/* 2.5D Curved Glass Perimeter Edge Refraction */}
              <div
                className="pointer-events-none absolute inset-0 z-15 rounded-[34px] sm:rounded-[38px] md:rounded-[42px] shadow-[inset_0_1px_1.5px_rgba(255,255,255,0.18),inset_0_-1px_1.5px_rgba(0,0,0,0.8),inset_1px_0_1px_rgba(255,255,255,0.06),inset_-1px_0_1px_rgba(0,0,0,0.5)]"
                aria-hidden="true"
              />

              {/* Apple iOS Home Indicator Bar — Centered & Subtle */}
              <div
                className="pointer-events-none absolute bottom-2 left-1/2 -translate-x-1/2 z-20 w-24 sm:w-28 h-[3.5px] bg-white/40 backdrop-blur-md rounded-full shadow-[0_1px_2px_rgba(0,0,0,0.6)]"
                aria-hidden="true"
              />

              {/* Optional Screen Status Badge */}
              {badge && (
                <div className="absolute bottom-5 left-1/2 -translate-x-1/2 z-30 px-3 py-1 rounded-full bg-black/85 backdrop-blur-md border border-brand-green/50 text-[11px] font-bold text-brand-green shadow-xl tracking-tight whitespace-nowrap">
                  {badge}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Screen Caption */}
      {caption && (
        <p className="mt-4 text-center text-xs sm:text-sm text-zinc-400 font-medium max-w-xs leading-relaxed">
          {caption}
        </p>
      )}
    </div>
  );
}
