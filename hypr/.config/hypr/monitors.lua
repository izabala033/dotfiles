-- Portable default for single-monitor sessions.
-- Dual-screen layout is applied dynamically at runtime when multiple outputs
-- are present, and keeps scale at 1 there.
-- Increase the final value to make the laptop screen bigger, or lower it for
-- more space.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1.25,
})
