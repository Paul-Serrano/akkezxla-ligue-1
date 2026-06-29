# CODING RULES

These rules always have priority when generating code.

---

# General philosophy

Write code as if it were intended for production.

Always prioritize:

- readability
- simplicity
- maintainability
- testability

Avoid unnecessary abstractions.

Avoid overengineering.

---

# Language

All code must be written in English.

Including:

- classes
- methods
- variables
- enums
- DTOs
- comments

Git commits may be written in French.

---

# PHP

Version:

PHP 8.4

Use every modern PHP feature when relevant.

Prefer:

- readonly classes
- readonly properties
- constructor promotion
- enums
- match
- named arguments
- typed properties
- return types everywhere

Never omit type hints.

---

# Laravel

Use Laravel conventions whenever possible.

Prefer framework features over custom implementations.

Avoid reinventing Laravel features.

---

# Architecture

Organize the project by feature.

Example:

```
app/

    Actions/

    DTO/

    Enums/

    Exceptions/

    Http/

    Models/

    Policies/

    Providers/

    Services/

    ValueObjects/
```

Avoid technical folders that become huge.

Keep related code close together.

---

# Controllers

Controllers must remain thin.

Responsibilities:

- validation
- authorization
- call services
- return responses

Business logic never belongs inside controllers.

---

# Services

Business logic belongs inside Services.

Services should be small.

One responsibility per service.

---

# Models

Use Eloquent.

Keep models lightweight.

Avoid huge models.

Business rules should stay inside Services.

---

# Validation

Always use Form Requests.

Never validate directly inside controllers.

---

# Responses

Always return JSON.

Use API Resources when appropriate.

Never expose database internals.

---

# Database

Use PostgreSQL.

Every schema modification must use migrations.

Never modify the database manually.

---

# Testing

Every important feature should have tests.

Prefer Feature tests.

Use Unit tests for isolated business logic.

---

# Code style

PSR-12

Laravel Pint

No unused imports.

No dead code.

No commented code.

No duplicated code.

---

# Static analysis

PHPStan maximum level compatible with Laravel.

Zero errors accepted.

---

# SOLID

Follow SOLID principles.

Especially:

Single Responsibility Principle

Dependency Injection

Composition over inheritance

---

# Dependencies

Do not install packages unless they provide significant value.

Always prefer Laravel native features.

---

# Security

Never trust user input.

Always validate requests.

Always authorize protected actions.

Never expose stack traces.

Never commit secrets.

Never hardcode credentials.

---

# Naming

Use explicit names.

Good:

```
CreatePlayerAction

UpdateMatchService

LeagueStandingDTO
```

Avoid vague names:

```
Manager

Helper

Tool

Utils

Common
```

---

# Comments

Write self-explanatory code.

Comments should explain *why*, never *what*.

Avoid obvious comments.

---

# Documentation

Every public service should contain concise PHPDoc when useful.

Complex business rules should be documented.

---

# Git

Small commits.

One logical change per commit.

Meaningful commit messages.

---

# Quality target

The generated code should look like it was written by an experienced Laravel developer.

Always prefer clean architecture over quick fixes.

Never generate placeholder code, TODOs or fake implementations unless explicitly requested.