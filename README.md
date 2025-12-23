# SQL Development Workspace

This repository is the central hub for my SQL-related work. It is organized to handle various types of projects—from business intelligence reports to application backend logic—while maintaining high standards for code versioning and deployment.

## 📂 Project Organization

To keep the workspace clean, projects are categorized by their specific purpose:

* **📊 Reports:** SQL scripts for data analysis, complex joins, and business-driven KPIs.
* **🏗️ AppBuilder:** Database logic, stored procedures, and triggers supporting application development.
* **📈 BI (Business Intelligence):** Data transformation, ETL scripts, and view definitions for dashboarding tools.
* **🛠️ Maintenance:** Optimization scripts, indexing strategies, and database cleanup tasks.

---

## 🌿 Branching Strategy

I use a disciplined branching model to ensure that every deployment to production is stable and tested:

### 1. Main (Production)
The "Source of Truth." This branch contains the code currently running in the live environment. No direct commits are made here.

### 2. Develop (Staging)
The integration branch. New features and scripts are merged here first to be tested against other recent changes.

### 3. Feature Branches (`feature/task-name`)
Where the actual work happens. Each new project, report, or fix starts as a feature branch. Once the code is ready, it is merged into `develop`.

---

## 🚀 Workflow for New Projects

1.  **Branch:** Create a new branch from `develop`: `git checkout -b feature/new-report`.
2.  **Develop:** Write and test the SQL scripts within the appropriate folder.
3.  **Validate:** Ensure the script follows the project's formatting standards.
4.  **Deliver:** Merge the feature into `develop`, and eventually `develop` into `main` for the final production release.

5.  ## 💼 Portfolio & Professional Growth
This repository is a public mirror of my professional SQL development. It demonstrates:
* **Advanced Querying:** Complex joins, CTEs (Common Table Expressions), and Window Functions.
* **Database Architecture:** Optimized DDL and schema design.
* **Professional Workflow:** Rigorous use of Gitflow (Main/Develop/Feature) to simulate enterprise-level delivery.

---

## 🌐 Connect with Me

I'm active on various platforms where I share my journey in SQL development and tech:

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/rafaeldxdy)
[![Instagram](https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white)](https://www.instagram.com/rafaeldxdy)

> **Note:** My Instagram is a private space for my personal daily life, while LinkedIn and GitHub are my primary professional hubs.
