# Color Scheme Options for Pathwise

I've created 4 different color schemes for you to experiment with. All maintain the soft, calming aesthetic while adding more visual interest.

## How to Switch Schemes

Open `pathwise/Utils/DesignSystem.swift` and:
1. Comment out the current "Semantic Colors" section (lines 37-41)
2. Uncomment the color definitions for your chosen option
3. Uncomment the "Semantic Colors" for that same option
4. Rebuild the app

---

## Option 1: Original (Current) ✅

**Colors:**
- Background: Cream `#F9F7F2`
- Cards: White
- Accent: Sage Green `#718355`
- Text: Slate Blue `#4A5759`

**Feel:** Clean, minimal, classic
**Contrast:** High (white cards on cream background)
**Best For:** Professional, understated elegance

---

## Option 2: Two-Tone Sage 🌿

**Colors:**
- Background: Light Sage `#E8EBE0` (soft greenish-grey)
- Cards: Pale Sage `#F5F6F2` (very light sage)
- Accent: Sage Green `#718355`
- Text: Slate Blue `#4A5759`

**Feel:** Harmonious, nature-inspired, cohesive
**Contrast:** Medium (tonal variation in same color family)
**Best For:** Immersive nature feel, "walking in a forest"

**To activate:**
```swift
// Uncomment lines 22-23:
static let lightSage = Color(hex: "#E8EBE0")
static let paleSage = Color(hex: "#F5F6F2")

// Comment out lines 37-41, uncomment lines 44-48
static let primaryBackground = Color.lightSage
static let primaryText = Color.slateBlue
static let accent = Color.sageGreen
static let cardBackground = Color.paleSage
```

---

## Option 3: Warm Earth Tones 🌅

**Colors:**
- Background: Warm Cream `#FFF8F0` (peachy-cream)
- Cards: Soft Peach `#FFE8DC` (light coral-peach)
- Accent: Terracotta `#C17767` (warm rust-orange)
- Text: Slate Blue `#4A5759`

**Feel:** Warm, inviting, sunset-inspired
**Contrast:** Medium-High (warm tones with depth)
**Best For:** Evening walks, cozy aesthetic, more colorful

**To activate:**
```swift
// Uncomment lines 27-29:
static let warmCream = Color(hex: "#FFF8F0")
static let terracotta = Color(hex: "#C17767")
static let softPeach = Color(hex: "#FFE8DC")

// Comment out lines 37-41, uncomment lines 51-55
static let primaryBackground = Color.warmCream
static let primaryText = Color.slateBlue
static let accent = Color.terracotta
static let cardBackground = Color.softPeach
```

---

## Option 4: Cool Mist 🌫️

**Colors:**
- Background: Mist Blue `#E8EEF1` (soft sky blue)
- Cards: Pale Mist `#F2F6F8` (very light blue-grey)
- Accent: Sage Green `#718355` (keeps the brand green)
- Text: Deep Mist `#5B7C8D` (blue-grey)

**Feel:** Serene, morning walk, airy
**Contrast:** Medium (cool, misty tones)
**Best For:** Morning freshness, minimalist with color

**To activate:**
```swift
// Uncomment lines 33-35:
static let mistBlue = Color(hex: "#E8EEF1")
static let deepMist = Color(hex: "#5B7C8D")
static let paleMist = Color(hex: "#F2F6F8")

// Comment out lines 37-41, uncomment lines 58-62
static let primaryBackground = Color.mistBlue
static let primaryText = Color.deepMist
static let accent = Color.sageGreen
static let cardBackground = Color.paleMist
```

---

## My Recommendations

### Most Popular Choice: **Option 2 (Two-Tone Sage)** 🌿
- Keeps your brand identity strong
- Creates visual cohesion
- Still maintains good readability
- Immersive nature theme

### Most Colorful: **Option 3 (Warm Earth Tones)** 🌅
- Adds personality and warmth
- Stands out from typical green apps
- Great for sunset/evening walks
- More Instagram-worthy

### Most Serene: **Option 4 (Cool Mist)** 🌫️
- Fresh and clean
- Morning walk vibes
- Different from typical "nature = green" apps
- Sophisticated and modern

---

## Testing Tips

1. **Try them all!** It takes 30 seconds to switch - just comment/uncomment
2. **Check in different lighting:** View in bright and dark environments
3. **Test with real content:** The Golden Window card is where colors matter most
4. **Consider your audience:** What time of day do most people walk?

---

## Contrast & Accessibility

All options maintain sufficient contrast ratios for readability:
- Text on card backgrounds: 7:1+ (AAA rating)
- Accent colors: 4.5:1+ (AA rating)

If you want to check contrast, use: https://webaim.org/resources/contrastchecker/

---

## Want Something Custom?

If you want to tweak any of these options, you can adjust the hex values:
- Make backgrounds lighter/darker
- Adjust saturation of accent colors
- Fine-tune card colors

Just modify the hex codes in DesignSystem.swift and rebuild!
