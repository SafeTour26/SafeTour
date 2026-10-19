---
name: SafeTour Design System
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c2c6d4'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#8c909e'
  outline-variant: '#424752'
  surface-tint: '#adc6ff'
  primary: '#adc6ff'
  on-primary: '#002e69'
  primary-container: '#5e92f3'
  on-primary-container: '#002a62'
  inverse-primary: '#1b5bb9'
  secondary: '#75daa8'
  on-secondary: '#003823'
  secondary-container: '#008056'
  on-secondary-container: '#d1ffe3'
  tertiary: '#e7c268'
  on-tertiary: '#3e2e00'
  tertiary-container: '#b1903c'
  on-tertiary-container: '#3a2a00'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a41'
  on-primary-fixed-variant: '#004494'
  secondary-fixed: '#92f7c3'
  secondary-fixed-dim: '#75daa8'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005235'
  tertiary-fixed: '#ffdf96'
  tertiary-fixed-dim: '#e7c268'
  on-tertiary-fixed: '#251a00'
  on-tertiary-fixed-variant: '#5a4400'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 8px
  gutter-mobile: 16px
  gutter-desktop: 24px
  margin-edge: 24px
  stack-sm: 12px
  stack-md: 24px
  stack-lg: 48px
---

## Brand & Style

This design system is built on a foundation of **Minimalist Modernism** with a focus on high-end utility and reassurance. It targets a sophisticated traveler who values safety without wanting to feel anxious. The aesthetic is inspired by the precision of productivity tools and the legibility of modern navigation interfaces.

The UI evokes a sense of "Quiet Intelligence"—calm, professional, and prepared. It avoids the alarmist visual language of traditional security apps in favor of a refined, premium experience that feels like a concierge service. Key attributes include:
*   **Confidence through clarity:** Massive amounts of negative space to reduce cognitive load.
*   **Tactile layering:** Using depth to separate information hierarchies.
*   **Softened edges:** Reducing visual tension through organic, approachable shapes.

## Colors

The palette is optimized for low-light environments and high-stress situations, ensuring legibility and comfort. 

*   **Foundation:** The core is built on **Matte Black (#121212)** for backgrounds and **Deep Charcoal (#1A1A1A)** for primary containers. This creates a sophisticated, ink-like depth.
*   **Accents:** 
    *   **Primary (Muted Blue):** Used for navigation and primary actions to signal reliability.
    *   **Success (Calm Emerald):** Denotes "Safe" zones and positive statuses.
    *   **Warning (Warm Amber):** Provides cautionary info without inducing panic.
    *   **Danger (Subtle Coral):** Reserved for SOS and critical alerts, utilizing a softer tone than standard red to maintain the system's calm demeanor.

## Typography

The typographic system utilizes a dual-font approach to balance personality with functional precision.

*   **Plus Jakarta Sans** is the voice of the brand. It is used for all headings and display elements. Its contemporary, slightly rounded geometry feels approachable and premium.
*   **Inter** handles all body copy, data, and UI labels. Its high legibility and neutral character ensure that critical safety information is consumed effortlessly.

Scale headlines aggressively on desktop for a high-fashion editorial feel, but ensure they collapse into a tight, readable hierarchy on mobile devices to prioritize map and safety-status visibility.

## Layout & Spacing

The layout philosophy follows a **Fluid Grid** model with significant horizontal padding to create a "protected" content area.

*   **The 8px Rhythm:** All spacing increments must be multiples of 8 to ensure a consistent vertical cadence.
*   **Negative Space:** Large margins (24px+) are mandatory for primary content cards to prevent the UI from feeling cluttered.
*   **Reflow:** On mobile, the system transitions to a single-column layout where the primary focus is a persistent bottom sheet containing contextual safety actions. On tablet and desktop, sidebars are used for secondary data feeds, keeping the central viewport dedicated to the map or core safety dashboard.

## Elevation & Depth

This design system uses **Tonal Layering** and **Subtle Blurs** rather than traditional heavy shadows. Depth is communicated through color value and transparency:

1.  **Base Layer:** The map or background (#121212).
2.  **Surface Layer:** Primary content cards (#1A1A1A) with a very subtle 1px border (#2A2A2A) to define edges.
3.  **Floating Layer:** Bottom sheets and modals use a glassmorphic effect (Background Blur: 20px, Opacity: 85%) to maintain context of the underlying map.
4.  **Shadows:** When used for floating buttons, shadows should be ultra-diffused: `0px 10px 30px rgba(0,0,0,0.5)`.

The goal is to create a sense of "physical sheets" being stacked on top of one another, similar to the Apple Maps paradigm.

## Shapes

The shape language is defined by **High Circularity**. 

*   **Containers:** Large cards and bottom sheets use a 24px to 32px corner radius. This softens the technical nature of the app and makes it feel more inviting.
*   **Interactive Elements:** Buttons and input fields should utilize a full pill-shape (circular ends) wherever possible.
*   **Consistency:** Avoid mixing sharp corners with rounded ones. Even small icons should feature rounded terminals to match the parent container's aesthetic.

## Components

### Buttons
*   **Primary:** Pill-shaped, muted blue background, white text. No gradient.
*   **Secondary:** Pill-shaped, transparent with a 1.5px subtle border.
*   **SOS Button:** Larger, Coral background, featuring a subtle outer glow to indicate urgency without being aggressive.

### Cards
*   Cards should never have a pure black background. Use the Surface color (#1A1A1A).
*   Corner radius: 24px.
*   Padding: 24px internal padding for large "breathable" content.

### Bottom Sheets
*   The signature component of the system.
*   Always feature a "Grab Handle" (a 40px wide, 4px thick rounded bar) at the top.
*   Use a backdrop blur effect when pulled up to cover more than 50% of the screen.

### Input Fields
*   Background: #242424.
*   Border: None, unless focused (then use 1.5px Primary Blue).
*   Radius: Pill-shaped (height: 56px).

### Chips & Badges
*   Used for safety statuses (e.g., "Safe Zone").
*   Small, high-radius (100px), with a subtle background tint of the status color (Emerald/Amber) and high-contrast text.