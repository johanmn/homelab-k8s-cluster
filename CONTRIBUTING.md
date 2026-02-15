# Contributing & Development Workflow

To maintain a clean and reliable homelab repository, we follow a branching strategy inspired by **GitHub Flow**.

## 🌲 Branching Strategy

Our `main` branch is the **single source of truth**. It reflects the actual, deployed state of the cluster.

### Branch Types
When working on new features or fixes, create a new branch from `main` using one of the following prefixes:

*   **`feat/`**: For new features or applications (e.g., `feat/argocd`, `feat/media-server`).
*   **`fix/`**: For bug fixes (e.g., `fix/networking-issue`, `fix/broken-pipeline`).
*   **`docs/`**: For documentation updates only (e.g., `docs/updated-diagrams`).
*   **`chore/`**: For maintenance tasks (e.g., `chore/upgrade-k8s-v1.33`, `chore/cleanup-scripts`).

### Naming Convention examples:
```bash
git checkout -b feat/add-prometheus-stack
git checkout -b fix/metallb-config
git checkout -b docs/update-readme
```

## 🔄 Workflow

1.  **Create a Branch**: Always start from `main`.
    ```bash
    git checkout main
    git pull origin main
    git checkout -b feat/your-feature-name
    ```

2.  **Commit Changes**: Make atomic commits with clear messages.
    ```bash
    git commit -m "feat: install prometheus using helm chart"
    ```

3.  **Push & Pull Request**: Push your branch to remote and open a Pull Request (PR) against `main`.

4.  **Review & Merge**: Review the changes, ensuring they don't break existing cluster functionality. Once approved, merge into `main`.

5.  **Deploy**: Apply the changes from `main` to your cluster (or let ArgoCD handle it automatically in later phases!).

## 📝 Commit Messages
We encourage using [Conventional Commits](https://www.conventionalcommits.org/):
*   `feat:` A new feature
*   `fix:` A bug fix
*   `docs:` Documentation only changes
*   `style:` Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
*   `refactor:` A code change that neither fixes a bug nor adds a feature
*   `perf:` A code change that improves performance
*   `test:` Adding missing tests or correcting existing tests
*   `build:` Changes that affect the build system or external dependencies
*   `ci:` Changes to our CI configuration files and scripts
*   `chore:` Other changes that don't modify src or test files
*   `revert:` Reverts a previous commit
