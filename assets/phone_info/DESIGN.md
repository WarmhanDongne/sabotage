---
name: 'Saboteur: Under the Surface'
colors:
  surface: '#121316'
  surface-dim: '#121316'
  surface-bright: '#38393c'
  surface-container-lowest: '#0d0e11'
  surface-container-low: '#1b1b1f'
  surface-container: '#1f1f23'
  surface-container-high: '#292a2d'
  surface-container-highest: '#343538'
  on-surface: '#e3e2e6'
  on-surface-variant: '#d0c6ab'
  inverse-surface: '#e3e2e6'
  inverse-on-surface: '#2f3034'
  outline: '#999077'
  outline-variant: '#4d4732'
  surface-tint: '#e9c400'
  primary: '#fff6df'
  on-primary: '#3a3000'
  primary-container: '#ffd700'
  on-primary-container: '#705e00'
  inverse-primary: '#705d00'
  secondary: '#ffb68c'
  on-secondary: '#532200'
  secondary-container: '#753401'
  on-secondary-container: '#fc9e65'
  tertiary: '#f7f6f6'
  on-tertiary: '#2f3131'
  tertiary-container: '#dbdada'
  on-tertiary-container: '#5e5f5f'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffe16d'
  primary-fixed-dim: '#e9c400'
  on-primary-fixed: '#221b00'
  on-primary-fixed-variant: '#544600'
  secondary-fixed: '#ffdbc9'
  secondary-fixed-dim: '#ffb68c'
  on-secondary-fixed: '#321200'
  on-secondary-fixed-variant: '#753401'
  tertiary-fixed: '#e3e2e2'
  tertiary-fixed-dim: '#c7c6c6'
  on-tertiary-fixed: '#1a1c1c'
  on-tertiary-fixed-variant: '#464747'
  background: '#121316'
  on-background: '#e3e2e6'
  surface-variant: '#343538'
  gold-glow: rgba(117, 52, 1, 0.4)
  panel-charcoal: '#292a2d'
  border-brass: '#4d4732'
  slot-overlay: rgba(0, 0, 0, 0.05)
typography:
  headline-lg:
    fontFamily: Literata
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Literata
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-sm:
    fontFamily: Literata
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Work Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Work Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.1em
  badge-label:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 24px
  card-gap: 12px
  margin-mobile: 16px
  margin-desktop: 40px
  sidebar-width: 384px
---

## Brand & Style
The brand personality is **Tactile & Mysterious**, designed to evoke the tension of a high-stakes subterranean search. It blends **Brutalism** (heavy charcoal panels and rigid grids) with **Tactile/Skeuomorphic** elements (physical card stacks and chiseled edges). 

The target audience is competitive tabletop gamers who appreciate high-immersion digital adaptations. The UI should feel like a physical control console or a surveyor's desk located deep underground. Visual cues like radial vignettes and "chiseled" border treatments reinforce the feeling of being enclosed and focused on the task at hand.

## Colors
The palette is dominated by a high-contrast relationship between deep "Panel Charcoal" and "Gold/Brass" accents. 

- **Primary (Gold):** Used for critical gameplay feedback, active timers, and status badges. It represents value and progress.
- **Secondary (Burnt Sienna/Brown):** Used for interaction states (hovers) and thematic warmth, echoing the "earthy" nature of a mine.
- **Backgrounds:** The main board uses a clean off-white (#ffffff to #f7f6f6) to ensure the game cards remain the focal point, while the sidebar uses dark surfaces to minimize distraction from the controls.
- **Functional Colors:** Use `surface-container` variants for card slot depths and panel layering.

## Typography
The system uses a tri-font approach to establish character and hierarchy:
- **Literata (Serif):** Used for primary headlines and storytelling elements. Its "bookish" quality adds a sense of history and gravitas.
- **Work Sans (Sans-Serif):** The workhorse for descriptions and general interface text, providing high legibility against varied backgrounds.
- **JetBrains Mono (Monospace):** Used for all technical data, labels, and "readouts" (like the card count and deck headers). This reinforces the "instrumentation" feel of the side panel.

## Layout & Spacing
The layout uses a **Hybrid Fixed-Fluid Model**:
- **Main Game Board:** A fluid 9x5 grid (`mine-grid`) that centers the gameplay. Card slots maintain a fixed 2:3 aspect ratio.
- **Control Panel:** A fixed-width (384px) right sidebar (`chiseled-panel`) that houses the deck, timer, and discard pile.
- **Rhythm:** A 4px base unit governs the system. Standard margins are 40px on desktop, scaling down to 16px on mobile. 
- **Responsive Behavior:** On mobile, the sidebar should collapse into a bottom drawer or a hidden overlay to maximize the grid view.

## Elevation & Depth
Depth is created through **Physical Metaphors** rather than ambient shadows:
- **Chiseled Edges:** The sidebar uses a 2px solid left border (`#4d4732`) to appear inset into the screen.
- **Card Stacking:** Use absolute positioning and offset layers (3px/2px/1px) with varying border opacities to simulate a physical deck of cards.
- **Sunken Slots:** Card slots on the grid use a 1px solid border with a dark background to appear "etched" into the board.
- **Interactive Glow:** Hover states use a `gold-glow` text shadow and container glow (`rgba(117, 52, 1, 0.2)`) rather than traditional elevation lifting.

## Shapes
The shape language is primarily **Rigid and Industrial**. 
- **Standard Radius:** 4px (Soft) for card slots and panels to prevent the UI from feeling too sharp while maintaining a "heavy" feel.
- **Circular Elements:** Reserved exclusively for progress indicators (like the Turn Timer) to distinguish dynamic status from static layout.
- **Badges:** Use "full" roundedness (Pill) for status badges (e.g., "42 REMAINING") to ensure they pop against the rectangular grid.

## Components
- **Game Cards:** 2:3 aspect ratio. Backs feature high-detail thematic art; fronts use standard game iconography.
- **The Draw Deck:** A 3D-stacked component. Interaction should include a slight vertical lift on hover (`-4px`).
- **Circular Timer:** A custom SVG component using a stroke-dasharray to show remaining time. The center can house icons or numeric readouts.
- **Chiseled Panels:** Vertical containers with a single distinct border side (brass) to simulate a physical join.
- **Grid Slots:** Empty state components with 30% opacity icons (Material Symbols Outlined) to suggest possible actions.
- **Discard Pile:** A dashed-border container with a grayscale filter, returning to full color only when a card is being dragged over it.