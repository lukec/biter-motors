# Biter Motors Compatibility

This contract begins with the first public Biter Motors release on
mods.factorio.com. Earlier private `factoryx` development builds are not public
release ancestors.

## Supported Game

- Factorio 2.1
- Space Age enabled
- Quality, Elevated Rails, and Recycler as supplied by Space Age
- New Biter Motors worlds
- Single-player and Factorio multiplayer

Release candidates are tested against the current Factorio 2.1 build. New
experimental Factorio builds are supported only after validation.

## World Scope

Biter Motors is a Nauvis-and-Nauvis-orbit campaign overhaul. It deliberately
hides the other Space Age planets, their routes, and technologies that do not
belong to this campaign.

Mods that require travel to hidden planets, replace the freeplay start, rewrite
the same technology tree, overhaul enemy forces, or replace Nauvis generation
should be assumed incompatible unless an adapter is documented.

## Save Policy

- Back up a world before every mod upgrade.
- Patch releases should preserve public saves.
- Minor releases should provide migrations when prototype or persistent runtime
  state changes.
- A future intentionally save-breaking release must say so prominently before
  publication and use a version boundary appropriate to the break.
- Removing Biter Motors from an active world is unsupported because the world
  contains custom entities, resources, forces, and technology state.

The one-time conversion of Luke's private development save from `factoryx` to
`bitermotors` is complete but is not shipped as a general migration.

## Namespace Contract

The stable public namespace is:

- Mod id: `bitermotors`
- Prototype prefix: `bitermotors-`
- Commands: `/bitermotors-*`
- Remote interface: `bitermotors`

The retired `factoryx` mod id and `x-` prototype prefix will not be reused as
aliases.

## Known Boundaries

- Biter Motors owns customer diplomacy, customer and road-rage forces, and
  several enemy lifecycle rules. Enemy-overhaul mods may conflict.
- Biter Motors changes the freeplay landing, selected vanilla research
  prerequisites, module progression, and access to relocated Space Age
  machinery.
- Biter Motors adds Nickel Ore and Lithium Brine to Nauvis generation.
- P.U.M.P. 2.2.1 is used in the current development playtest and is compatible;
  it is not a required dependency.
- Factorio Coach is a separate optional project. Neither project depends on the
  other.

## Reporting Compatibility Problems

Include:

1. Factorio version.
2. Biter Motors version.
3. Full enabled-mod list.
4. Whether the world was created with Biter Motors.
5. The relevant `factorio-current.log` error and reproduction steps.
