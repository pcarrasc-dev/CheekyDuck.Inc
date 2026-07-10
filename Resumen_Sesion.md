# Resumen de Sesión — Ajustes Físicos CheekyDuck.Inc

## Bug Fixes (preservados todo el tiempo)

- `continuous_cd = true` en el balón (new_ball.tscn)
- Physics FPS 120 (project.godot)
- `ball_spawn.y = 0.2` en escena.gd y skill_double.gd (balón spawn en la mesa, no del cielo)
- Dirección de escape sesgada a lo largo del eje Z (nunca a los arcos en X)
- Gol con desliz hacia el equipo que recibe (dir * 6.0)
- `_goal_processed` Dictionary para evitar doble conteo + polling fallback en `_process`

## Problemas Detectados y Soluciones

### 1. Default damp del proyecto inexistente (se sumaba al del nodo)

**Síntoma:** El balón frenaba mucho más de lo que indicaba `linear_damp=0.03`.

**Causa:** No había `default_linear_damp` ni `default_angular_damp` en project.godot. Godot usa defaults internos (~0.1 lineal) que se suman al damp del nodo. El damp efectivo era ~0.13.

**Fix:** `project.godot` → `[physics]`
```
3d/default_linear_damp=0.0
3d/default_angular_damp=0.0
```

### 2. linear_damp/angular_damp del balón muy altos

**Síntoma:** Balón frenaba rápido y no rodaba naturalmente.

**Fix:** `new_ball.tscn`
```
linear_damp = 0.03 → 0.01
angular_damp = 0.4  → 0.1
```

### 3. Hard clamp cortando velocidad abruptamente

**Síntoma:** Golpes fuertes se sentían como "frenado artificial" porque velocidad >48 se truncaba a 32 en un frame.

**Fix:** `new_ball.gd`
```
HARD_CLAMP_THRESHOLD = 48 → 80
```

### 4. Fricción de suelo potencialmente alta para esferas en Jolt

**Síntoma:** Balón no se deslizaba libremente. Reportado como bug conocido de esferas contra superficies en algunos motores.

**Fix:** `Field_V2.tscn`
```
suelo friction = 0.08 → 0.02
```

### 5. GoalAreaB con collision_layer = 0

**Síntoma:** Algunos goles no se detectaban.

**Causa:** `collision_layer = 0` en GoalAreaB (Escena.tscn:136). GoalAreaA no lo tenía.

**Fix:** Removida la línea `collision_layer = 0`. Ahora ambas áreas usan default (layer 1).

### 6. Balón giraba desincronizado entre server y cliente

**Síntoma:** Tras bajar angular_damp, el giro era visible pero no se replicaba igual.

**Causa:** `MultiplayerSynchronizer` tenía autoridad `Game.players[0].id` (cliente) y no replicaba `angular_velocity` ni `linear_velocity`.

**Fix:** `new_ball.gd`
```
multiplayer_synchronizer.set_multiplayer_authority(1)  # server
```
`new_ball.tscn` — agregado al SceneReplicationConfig:
```
properties/2/path = NodePath(".:linear_velocity")
properties/3/path = NodePath(".:angular_velocity")
```

### 7. Paredes sin bounce

**Fix:** `Field_V2.tscn` — agregado `PhysicsMaterial_paredes` con `bounce = 0.15` al nodo Paredes.

### 8. Dirección del input de barras por jugador

**Fix:** `Bar.gd` — P0 usa `+mouse.y`, P1 usa `-mouse.y` (en vez de position.z).

## Valores Finales

| Propiedad | Archivo | Valor |
|---|---|---|
| mass | new_ball.tscn | 2.3 |
| gravity_scale | new_ball.tscn | 1.8 |
| linear_damp | new_ball.tscn | 0.01 |
| angular_damp | new_ball.tscn | 0.1 |
| friction (ball) | new_ball.tscn | 0.3 |
| bounce (ball) | new_ball.tscn | 0.05 |
| MAX_SPEED | new_ball.gd | 32.0 |
| HARD_CLAMP_THRESHOLD | new_ball.gd | 80.0 |
| ESCAPE_IMPULSE | new_ball.gd | 0.8 |
| STUCK_TIME_THRESHOLD | new_ball.gd | 0.3 |
| friction (player) | player.tscn | 0.35 |
| bounce (player) | player.tscn | 0.1 |
| friction (bar) | Bar.gd | 0.3 |
| bounce (bar) | Bar.gd | 0.1 |
| friction (suelo) | Field_V2.tscn | 0.02 |
| bounce (suelo) | Field_V2.tscn | 0.05 |
| bounce (paredes) | Field_V2.tscn | 0.15 |
| Bar input curve | Bar.gd | `pow(abs, 1.2) * 0.0005 * 0.47` |
| traslation_limit | Bar.gd | 0.18 |
| default_linear_damp | project.godot | 0.0 |
| default_angular_damp | project.godot | 0.0 |
| physics_ticks_per_second | project.godot | 120 |
| GoalArea collision_layer | Escena.tscn | default 1 (ambas) |
| ball_reset after goal | escena.gd | `dir * 6.0` en X |
| goal polling | escena.gd | `_goal_poll()` en `_process` |
| sync authority | new_ball.gd | server (1) |
