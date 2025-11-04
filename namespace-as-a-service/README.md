# Namespace as a Service

This chart lets you easily onboard new applications and users into Kubernetes/OpenShift.

While the controls and options can be expansive, this example aims to build a decent foundation for adaptation.  Key focus points are:

- Namespace creation
  - Annotations
  - Labels
- {ApplicationAware}ResourceQuotas and LimitRanges based on t-shirt sizes
- RBAC alignment to Users and Groups
- Default NetworkPolicy

Other things can be added, but those are common concerns.

## Core Concepts

- Configuration is largely determined based on "T-Shirt sizes" - this could be easily adapted to determinations based on apps/env/groups/teams/users/etc or even just configuration template names.
- To keep things simple,
- When on-boarding a new app/user, you simply make a PR against the inclusion repo

## Labels

Labels/Tagging is an opinionated thing - this Helm Chart uses the following examples:

- `naas.kemo.dev/requester` to signify the requesting `{user|sa/ns}-{name}`
- `naas.kemo.dev/sizing` for the "T-Shirt Size"
- `naas.kemo.dev/tenant` for tenant grouping, eg internal/external/team-based/etc.  Could as easily be something like Billing Group/Business Unit/etc.
- `naas.kemo.dev/environment` for segmenting dev/test, preprod, and prod

And some additional labels help glue things into ACM:

- `naas.kemo.dev/virtualization` to denote a NS with VMs
- `naas.kemo.dev/devspaces` for a DevSpaces enabled namespace

Based on those labels being set on the Namespace, you can either use it as just a bit of metadata - or in combination with ACM/Kyverno to manage resources that are not subject to Chart updates or Git modifications.

## Workflow

- Fork this repo - this is your Chart repo.  Manage the templates and logic as you see fit.
- Create a new repo - this is your Cluster Onboarding repo.
- In the Cluster Onboarding repo, make a set of folders like so:

```
clusters/${CLUSTER_NAME}/
                          argocd/naas-apps/argo-app.${APP_NAME}.yaml
                          naas-values/values.${APP_NAME}.yaml
```

- When onboarding an application/user, you create a new Helm Values file in the appropriate place,

## Mini ADRs

**Why Helm, why not an ADO/Ansible/etc pipeline?**

You don't want some one-shot deployment via a pipeline because after that pipeline is run, the state can drift.  To solve this, we use GitOps of course.
If you alter the pipeline to then submit artifacts to a repo, the state of those artifacts can be updated and synced, but updating many artifacts at scale can be daunting.
Helm Charts can be versioned and updated dynamically as new configuration is needed to be applied.  By storing the Helm values in a repo, we can distribute the applications widely and update them easily atomically and enmass.

**Why path-based cluster placement, why not an AppSet with matchExpressions?**

Typically app teams don't know about cluster names - they may know that their app runs in dev like vanilla and in prod like chocolate.  An AppSet with matchExpressions would be great for just putting the flavors where they need to be.
However, not everyone uses the ACM and GitOps integration or cluster labels in ArgoCD - it is very common however to use cluster/environment based pathing in an AppOfApps pattern.
Both examples exist here, however AppSet placement would occur on the Hub cluster, so the inclusion and pathing needs to be adjusted to fit that - more or less the same thing, just putting the AppSet in the Hub cluster managed AppOfApps repo/path and pointing things where they need to be.