```markdown
# autonomous-maintainer-skill Development Patterns

> Auto-generated skill from repository analysis

## Overview
The `autonomous-maintainer-skill` repository provides TypeScript utilities and documentation to support autonomous maintenance and policy management for codebases. This skill teaches best practices for maintaining policy documentation, adhering to consistent coding conventions, and managing updates through clear workflows.

## Coding Conventions

**File Naming**
- Use PascalCase for all file names.
  - Example: `PolicyManager.ts`, `SkillUtils.ts`

**Import Style**
- Use relative imports for modules within the repository.
  - Example:
    ```typescript
    import { PolicyManager } from './PolicyManager';
    ```

**Export Style**
- Use named exports for all modules.
  - Example:
    ```typescript
    // In PolicyManager.ts
    export function updatePolicy() { ... }
    ```

**Commit Messages**
- Freeform, no strict prefix required.
- Average commit message length: ~53 characters.
  - Example:  
    ```
    Update policy language for clarity and consistency
    ```

## Workflows

### Policy Documentation Update
**Trigger:** When you need to update or rewrite policy documentation to strengthen or clarify policies.  
**Command:** `/update-policy-docs`

1. Edit `SKILL.md` or `standalone/SKILL.md` to update policy language as needed.
2. Commit your changes with a message referencing policy or discovery rewrites.
   - Example commit message:  
     ```
     Clarify policy documentation in SKILL.md
     ```
3. (Optional) Use the `/update-policy-docs` command to signal the workflow.

## Testing Patterns

- Test files follow the `*.test.*` naming convention.
  - Example: `PolicyManager.test.ts`
- The testing framework is not explicitly specified.
- Place test files alongside the modules they test or in a dedicated test directory.

## Commands

| Command              | Purpose                                                      |
|----------------------|--------------------------------------------------------------|
| /update-policy-docs  | Initiate or signal a policy documentation update workflow    |
```
