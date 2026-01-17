# Contributing

Thanks for your interest in contributing to this project!

## How to Contribute

1. **Fork the repo** and create your branch from `main`
2. **Make your changes** following the existing patterns
3. **Test locally** using `helm lint` and `kustomize build`
4. **Submit a PR** with a clear description

## Code Style

- YAML files: 2-space indentation
- Use consistent naming: `<app>-<type>-<env>.yaml`
- Include proper labels on all resources
- Add comments for non-obvious configurations

## Adding New Examples

When adding new application examples:

1. Include both Helm and Kustomize versions if possible
2. Provide all three environment variants (dev, staging, prod)
3. Use realistic resource limits
4. Include health checks (liveness/readiness probes)

## Testing

Before submitting:

```bash
# Lint Helm charts
helm lint helm-charts/<chart>

# Build Kustomize overlays
kustomize build kustomize/<app>/overlays/dev

# Validate YAML syntax
find . -name "*.yaml" -exec python3 -c "import yaml; yaml.safe_load(open('{}'))" \;
```

## Questions?

Open an issue for bugs, feature requests, or questions.
