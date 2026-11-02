# Salary Manager API

Rails 8.1 API (PostgreSQL) for the Salary Manager. Setup, commands and Docker usage are in the
[project README](../README.md); design and trade-offs in [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md).

```bash
bin/rails db:setup        # create, load schema, seed 10,000 employees
bin/rails server          # http://localhost:3000
bin/ci                    # style, specs, security checks
```
