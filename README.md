**Cahier de TP - Projet 1**

_Pipeline CI/CD DevSecOps securise avec FastAPI, Docker et GitHub Actions_

  

# Fiche d'identite du TP

**Champ**

**Contenu**

Projet

Pipeline DevSecOps

Duree conseillee

2 semaines ou 4 demi-journees

Objectif professionnel

Automatiser les controles de securite dans une chaine CI/CD.

Repo GitHub attendu

tp-devsecops-pipeline

Posture attendue

Travailler comme un junior DevSecOps: documenter, automatiser, securiser, prouver.

  

# Regles pedagogiques communes

·      **\[ \]** Un commit Git clair apres chaque etape terminee.

·      **\[ \]** Un README a jour avec objectif, architecture, commandes, captures et resultats.

·      **\[ \]** Aucun secret dans Git: utiliser .env.example et GitHub Secrets.

·      **\[ \]** Chaque livrable doit etre demontrable en entretien en moins de 5 minutes.

·      **\[ \]** Chaque erreur importante doit etre notee dans docs/retours-experience.md.

# Competences visees

**Competence**

**Preuve attendue**

Git

Repo propre, historique de commits, README exploitable

Python FastAPI

API minimale testable localement

Docker

Image construite et lancee sans manipulation complexe

GitHub Actions

Workflow sur push et pull request

SAST, SCA, container scan

Bandit, pip-audit et Trivy integres

  

# Architecture cible

tp-devsecops-pipeline/

app/main.py

tests/test\_health.py

.github/workflows/ci.yml

Dockerfile

requirements.txt

.gitignore

.env.example

README.md

docs/rapport-securite.md

docs/retours-experience.md

# TP 1 - Initialiser le repo et l'environnement

mkdir tp-devsecops-pipeline

cd tp-devsecops-pipeline

git init

python3 -m venv .venv

source .venv/bin/activate

python -m pip install --upgrade pip

cat > requirements.txt <<'EOF'

fastapi==0.115.6

uvicorn\[standard\]==0.34.0

pytest==8.3.4

httpx==0.28.1

bandit==1.8.0

pip-audit==2.7.3

EOF

pip install -r requirements.txt

cat > .gitignore <<'EOF'

.venv/

\_\_pycache\_\_/

.pytest\_cache/

.env

\*.pyc

EOF

cat > .env.example <<'EOF'

APP\_ENV=dev

EOF

# TP 2 - Creer l'API et les tests

mkdir -p app tests docs

touch app/\_\_init\_\_.py

cat > app/main.py <<'EOF'

from fastapi import FastAPI

app = FastAPI(title="DevSecOps Training API")

@app.get("/health")

def health() -> dict\[str, str\]:

   return {"status": "ok"}

EOF

cat > tests/test\_health.py <<'EOF'

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

def test\_health\_endpoint():

   response = client.get("/health")

   assert response.status\_code == 200

   assert response.json() == {"status": "ok"}

EOF

pytest -q

# TP 3 - Dockeriser

cat > Dockerfile <<'EOF'

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt

COPY app ./app

EXPOSE 8000

CMD \["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"\]

EOF

docker build -t tp-devsecops-pipeline:local .

docker run --rm -p 8000:8000 tp-devsecops-pipeline:local

curl http://localhost:8000/health

# TP 4 - Controles securite locaux

bandit -r app

pip-audit -r requirements.txt

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image tp-devsecops-pipeline:local

# TP 5 - GitHub Actions

mkdir -p .github/workflows

cat > .github/workflows/ci.yml <<'EOF'

name: CI DevSecOps

on:

 push:

   branches: \[ main \]

 pull\_request:

   branches: \[ main \]

jobs:

 test-and-security:

   runs-on: ubuntu-latest

   steps:

     - uses: actions/checkout@v4

     - uses: actions/setup-python@v5

       with:

         python-version: '3.12'

     - name: Install dependencies

       run: |

         python -m pip install --upgrade pip

         pip install -r requirements.txt

     - name: Tests

       run: pytest -q

     - name: SAST Bandit

       run: bandit -r app

     - name: SCA pip-audit

       run: pip-audit -r requirements.txt

     - name: Build Docker image

       run: docker build -t tp-devsecops-pipeline:ci .

     - name: Trivy container scan

       uses: aquasecurity/trivy-action@master

       with:

         image-ref: 'tp-devsecops-pipeline:ci'

         format: 'table'

         severity: 'CRITICAL,HIGH'

         exit-code: '1'

EOF

# Validation responsable formation

·      **\[ \]** Le pipeline GitHub Actions passe sur push.

·      **\[ \]** Le pipeline echoue si Trivy detecte une vulnerabilite critique.

·      **\[ \]** Le README permet a un tiers de relancer le TP.

·      **\[ \]** Le rapport docs/rapport-securite.md explique outils, resultats et limites.

·      **\[ \]** Le repo peut etre montre sur CV, Malt ou LinkedIn.
