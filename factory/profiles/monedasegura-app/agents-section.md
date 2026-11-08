
### This repo (monedasegura-app)

- **Team.** Juan José (`@Jujoroco06`) and Santiago (`@Gomaxd11`) build this repo; the planner assigns each task to one of them. Nicolás (`@nickkmm`) runs `/factory divide` and reviews.
- **Design.** The Figma prototype and component gallery: https://www.figma.com/design/UQgvVVY2Sd9lRZY6cVPISY. Issues created by `/factory divide` already carry the values a builder needs (colors, sizes, copy, states, node ids), so building one never requires Figma access.
- **How to check a page here.** There is no browser tool for agents, and Flutter web draws on a canvas. Builders and reviewers check UI work with widget tests (`flutter test`) and by reading the code against the values in the issue; a person walks through the app with `flutter run -d chrome`. Every new screen, page and shared widget gets widget tests for its acceptance criteria.
- **Structure.** Each reusable component is one widget in a shared widgets folder, built once and reused. The state lives in the host Screen; Pages only show data and capture interaction, reporting up through callbacks, and never keep app data of their own. Mock data are in-memory models and lists consistent with `../monedasegura-infra/docs/model.md`; creating, editing or deleting updates what the screen shows.
- **Current delivery.** `docs/deliveries/flutter-prototype.md`.
