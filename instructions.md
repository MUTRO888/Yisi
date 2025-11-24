
# Development Guidelines

## Philosophy

### Core Beliefs

- **Incremental progress over big bangs** - Small changes that compile and pass tests
- **Learning from existing code** - Study and plan before implementing
- **Pragmatic over dogmatic** - Adapt to project reality
- **Clear intent over clever code** - Be boring and obvious
- **Code efficiency over redundancy** - Carefully study existing code before adding new functionality, reuse patterns and utilities, avoid creating duplicate solutions
- **Quality over quantity** - Reject redundant code, maintain clean architecture, never contribute to technical debt

### Simplicity Means

- Single responsibility per function/class
- Avoid premature abstractions
- No clever tricks - choose the boring solution
- If you need to explain it, it's too complex

## Process

### 1. Planning & Staging

Break complex work into 3-5 stages. Document in `IMPLEMENTATION_PLAN.md`:

```markdown
## Stage N: [Name]
**Goal**: [Specific deliverable]
**Success Criteria**: [Testable outcomes]
**Tests**: [Specific test cases]
**Status**: [Not Started|In Progress|Complete]

```

- Update status as you progress
- Remove file when all stages are done

### 2. Implementation Flow

1. **Understand** - Study existing patterns in codebase
2. **Test** - Write test first (red)
3. **Implement** - Minimal code to pass (green)
4. **Refactor** - Clean up with tests passing
5. **Commit** - With clear message linking to plan

### 3. Git & Version Control

**CRITICAL RULE**: AI must NEVER execute git operations without explicit user request.

- **AI Role**: Modify code files only
- **User Role**: Control all version operations (add, commit, push)
- **Repository Ownership**: User maintains complete control over repository state
- **Version History**: All commits and version iterations are user-driven

**AI Behavior**:
- ✅ **ALLOWED**: Modify, create, delete code files
- ✅ **ALLOWED**: Suggest git commands when asked
- ❌ **FORBIDDEN**: Execute `git add`, `git commit`, `git push` without explicit user request
- ❌ **FORBIDDEN**: Any automatic repository synchronization

**Exceptions**: AI may execute git commands ONLY when:
- User explicitly requests git operations
- User is learning git workflow (educational purposes)
- User specifically asks for help with git commands

This ensures users maintain full control over their repository history and version management.

### 4. When Stuck (After 3 Attempts)

**CRITICAL**: Maximum 3 attempts per issue, then STOP.

1. **Document what failed**:
    - What you tried
    - Specific error messages
    - Why you think it failed
2. **Research alternatives**:
    - Find 2-3 similar implementations
    - Note different approaches used
3. **Question fundamentals**:
    - Is this the right abstraction level?
    - Can this be split into smaller problems?
    - Is there a simpler approach entirely?
4. **Try different angle**:
    - Different library/framework feature?
    - Different architectural pattern?
    - Remove abstraction instead of adding?

## Technical Standards

### Architecture Principles

- **Composition over inheritance** - Use dependency injection
- **Interfaces over singletons** - Enable testing and flexibility
- **Explicit over implicit** - Clear data flow and dependencies
- **Test-driven when possible** - Never disable tests, fix them

### Code Quality

- **Every commit must**:
    - Compile successfully
    - Pass all existing tests
    - Include tests for new functionality
    - Follow project formatting/linting
- **Before committing**:
    - Run formatters/linters
    - Self-review changes
    - Ensure commit message explains "why"

### Code Style Standards

- **No unnecessary decorations** - Avoid using emoji in code and frontend UI unless explicitly requested by user
- **Minimal meaningful comments** - Remove unnecessary comments, keep only essential documentation that adds value
- **Clean code principles** - Code should be self-documenting through clear naming and structure

### Error Handling

- Fail fast with descriptive messages
- Include context for debugging
- Handle errors at appropriate level
- Never silently swallow exceptions

## Decision Framework

When multiple valid approaches exist, choose based on:

1. **Testability** - Can I easily test this?
2. **Readability** - Will someone understand this in 6 months?
3. **Consistency** - Does this match project patterns?
4. **Simplicity** - Is this the simplest solution that works?
5. **Reversibility** - How hard to change later?

## Project Integration

### Learning the Codebase

- Find 3 similar features/components
- Identify common patterns and conventions
- Use same libraries/utilities when possible
- Follow existing test patterns

### Tooling

- Use project's existing build system
- Use project's test framework
- Use project's formatter/linter settings
- Don't introduce new tools without strong justification

## Quality Gates

### Definition of Done

- [ ]  Tests written and passing
- [ ]  Code follows project conventions
- [ ]  No linter/formatter warnings
- [ ]  Commit messages are clear
- [ ]  Implementation matches plan
- [ ]  No TODOs without issue numbers

### Test Guidelines

- Test behavior, not implementation
- One assertion per test when possible
- Clear test names describing scenario
- Use existing test utilities/helpers
- Tests should be deterministic

## Important Reminders

**NEVER**:

- Use `-no-verify` to bypass commit hooks
- Disable tests instead of fixing them
- Commit code that doesn't compile
- Make assumptions - verify with existing code

**ALWAYS**:

- Commit working code incrementally
- Update plan documentation as you go
- Learn from existing implementations
- Stop after 3 failed attempts and reassess
## Design & Aesthetics

### Design Philosophy

- **MUJI-inspired minimalism** - Clean, functional design with purposeful simplicity
- **Swiss International Typography** - Clear hierarchy, readable typography, grid-based layouts
- **Aesthetic excellence** - Every interface must be visually appealing, comfortable, and elegant
- **Contextual adaptation** - While maintaining core aesthetic principles, adapt design to specific requirements and contexts

### Visual Standards

- **Minimal visual noise** - Remove unnecessary decorative elements
- **Purposeful color** - Use color intentionally to guide attention and create hierarchy
- **Whitespace mastery** - Embrace negative space as a design element
- **Typography clarity** - Prioritize readability and information hierarchy
- **Consistent spacing** - Use systematic spacing patterns and grid alignment
