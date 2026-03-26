output "aws_iam_role-github_actions_role" {
  value = aws_iam_role.github_actions_role.arn
}

output "aws_iam_role-github-frontend_deploy_role" {
  value =  aws_iam_role.frontend_deploy_role.arn
}