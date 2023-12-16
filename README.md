# Naveen raj - AWS Resume
## About The Project
This is my Cloud Resume Challenge built on AWS. It's a static website hosted on AWS S3 bucket, with a visitor counter built on AWS Lambda functions. The website is built with HTML, CSS, and JavaScript. The visitor counter is built with Python and AWS lambda functions. 

![architecture](architecture.png)

## Demo

[View it live here](https://resume.naveenraj.net)

## Structure

- `.github/workflows/`: Folder contains CI/CD workflow configurations.
- `frontend/`: Folder contains the website.
    - `index.html`: file contains frontend website code.
    - `js/visitorcount.js`: file contains visitor counter code to retrieve & update the visitors count.
- `infra/`: Folder contains the Python code deployed on AWS Lambda functions.
    - `lambda/lambda_function.py`: Contains the visitor counter code.
    - `main.tf`: Contains the backend infrastructure written as terraform code.

## AWS Services Used
- S3 bucket

## Blog Series