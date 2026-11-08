# Delivery: navigable Flutter prototype

The input for `/factory divide docs/deliveries/flutter-prototype.md`. It states
what the course asks for, where the design and the data come from, and what
every task must contain so that each one can be built on its own.

## The assignment (verbatim, in Spanish)

> **Prototipo navegable en Flutter**
>
> Esta entrega lleva el diseño de la entrega anterior a código: el prototipo de la app en Flutter, con sus componentes, sus pantallas y la navegación entre ellas. Todavía no se conecta a la nube: funciona con datos simulados, y esos datos deben tener sentido con el modelo de base de datos del equipo.
>
> **Componentes y pantallas**
> Los componentes de la galería (botones, campos de texto, tarjetas, barras, y los propios de su app) se construyen como widgets reutilizables, cada uno una sola vez. Con ellos se arman las pantallas del recorrido principal: entrar, ver la lista, abrir un detalle, crear algo.
>
> **Estado y comunicación**
> El estado vive en la Screen anfitriona. Las Pages muestran y capturan la interacción, y reportan hacia arriba con callbacks. Ninguna Page guarda por su cuenta los datos de la app.
>
> **Navegación**
> La app se puede recorrer de punta a punta: rutas entre pantallas y, si el diseño lo pide, barra de navegación inferior. Los datos son simulados (listas y modelos en memoria), pero crear, editar o eliminar se refleja en pantalla.
>
> **Entregables**
> - El repositorio con el código del prototipo, con permiso de lectura para el profesor.
> - Un video corto (máximo 2 minutos) recorriendo la app de principio a fin.

## Sources

| What | Where |
|---|---|
| Screens, component gallery and every visual value | Figma: https://www.figma.com/design/UQgvVVY2Sd9lRZY6cVPISY |
| Screen list | `../monedasegura-infra/docs/MVP_PLAN.md` §6: Login · Case queue · Transaction/case detail · Rule list · Create/edit rule · Simulator · Dashboard |
| Entities, fields and allowed values for the mock data | `../monedasegura-infra/docs/model.md` (RBAC §4, rule lifecycle §6, cases §7) |
| Field names and enums as the API will send them | `../monedasegura-infra/docs/api/decision-api.yaml` |
| Rule-editor features | `../monedasegura-infra/docs/features.md` |
| Repo rules (language, permissions, structure) | `AGENTS.md` |

## Requirements for the plan

1. **Cover the whole assignment.** Every component in the Figma gallery
   becomes one reusable widget, built once. Every screen of the main journey is
   built from those widgets, and the app can be walked through end to end with
   routes (plus the bottom bar or side navigation if the design has one).
2. **State.** Name, in each task, the host Screen that owns the state and the
   callbacks each Page reports up. No Page keeps app data of its own.
3. **Mock data.** In-memory models and lists whose classes, fields and values
   follow `model.md` and the API's enums (`APPROVE | REVIEW | BLOCK`,
   `OPEN | IN_REVIEW | RESOLVED`, `CONFIRMED_FRAUD | DISMISSED`, rule statuses,
   permission codes). Personal data appears masked, as the API would send it.
   Login is simulated: the mock users' permissions decide which screens and
   actions show, never their role names.
4. **Create, edit, delete.** At least one flow where creating, editing and
   deleting updates what the screen shows, consistent with the domain rules in
   `model.md`: only a `DRAFT` rule version is edited, an `ACTIVE` one never is
   (a change creates a new version), and labeling a case moves it out of the
   open queue. `model.md` doesn't define deleting anything; list the delete
   action you choose, and why it fits the model, under the plan's decisions.
5. **Copy.** On-screen text in Spanish, exactly as in Figma; code, identifiers,
   tests and docs in English. API codes are translated for display.
6. **Foundations first.** Theme and tokens, the mock data layer, shared widgets
   and the router are their own tasks, and the screens depend on them, so two
   tasks never edit the same files at once.
7. **Every task is self-sufficient.** It carries the exact values from Figma
   (hex colors, sizes and spacing in logical pixels, font sizes and weights,
   copy, states, node ids), the files and names to create or reuse, and
   acceptance criteria checkable with widget tests. Someone without Figma or
   the factory must be able to build it from the issue alone.
8. **Owners.** Split the tasks between `@Jujoroco06` and `@Gomaxd11`, keeping
   each chain of dependent tasks with one person where possible.
9. **Not for the factory.** The 2-minute video and the professor's read access
   (the repo is public) are listed in the plan, not turned into tasks.
