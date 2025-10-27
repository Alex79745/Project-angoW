# 🧹 Repository Cleanup & History Reset Guide

## ⚠️ Background

Sensitive data (Terraform variables, private keys, or state files) was previously committed to this repository.  
To prevent future exposure, the repository history was **rewritten and cleaned** using **BFG Repo-Cleaner** on Windows.

---

## 🧰 Environment Setup (Windows + Chocolatey)

### 1. Install Dependencies

Run PowerShell **as Administrator**:

```powershell
choco install temurin17 -y
choco install git -y
choco install bfg-repo-cleaner -y

##fixing the “Could not find Java (1.8 required)” Error
ERROR: Could not find Java (1.8 required)

#Run it directly via java -jar:

java -jar "C:\ProgramData\chocolatey\lib\bfg-repo-cleaner\tools\bfg-1.14.0.jar" ^
  --delete-files "terraform.tfvars,*.tfstate,*.tfstate.backup,*.pem,*.key" ^
  --delete-folders ".vagrant" --no-blob-protection


##Post-BFG Cleanup Commands the logs might gime those commands
  git reflog expire --expire=now --all
  git gc --prune=now --aggressive

#Force Push the Clean History to GitHub

#Once verified locally, push the clean history to your remote repository:

git push --force origin main

#⚠️ This overwrites all existing history on GitHub — ensure no collaborators push old commits afterward.