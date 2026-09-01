[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dependabot](https://img.shields.io/badge/Dependabot-active-0288d1?logo=dependabot)](./.github/dependabot.yml)  

# 🚀 DevOps & Cloud Engineering Lab

Repositorio de aprendizaje y arquitectura de infraestructura, contenedores, orquestación, GitOps y observabilidad.

---

## 📌 Resumen de Fases Completadas

### 🟢 Fase 1: Entorno de Desarrollo Local
* Configuración de **WSL2 (Ubuntu)** integrado en Windows 11.
* Instalación de herramientas CLI (`kubectl`, `helm`, `kind`, `docker`, `git`).

### 🟢 Fase 2: Control de Versiones y Workflow
* Gestión de código y repositorios en GitHub.
* Flujo de trabajo basado en commits declarativos y ramas.

### 🟢 Fase 3: Empaquetado de Aplicaciones (Helm)
* Construcción de un **Helm Chart** completo (`mi-app`).
* Parametrización de manifiestos mediante `values.yaml` (Deployments, Services).

### 🟢 Fase 4: GitOps y Despliegue Continuo (ArgoCD)
* Instalación de **ArgoCD** en clúster local `kind`.
* Patrón declarativo con reconciliación automática y **Self-Healing** (autorrecuperación ante desviaciones de infraestructura).

### 🟢 Fase 5: Observabilidad y Monitorización
* Despliegue de **Kube-Prometheus-Stack** mediante GitOps.
* Configuración de **ServiceMonitor** para el rastro de la aplicación en el namespace `dev`.
* Dashboards visuales en **Grafana** (PromQL) y reglas de alerta automatizadas con **PrometheusRule / Alertmanager**.

---

## 🛠️ Stack Tecnológico Utilizado
`WSL2` | `Docker` | `Kubernetes (Kind)` | `Helm` | `ArgoCD` | `Prometheus` | `Grafana`
