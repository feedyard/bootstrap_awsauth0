function (user, context, callback) {
    user.app_metadata.roles.forEach(function(role) {
        if (role === 'feedyard/aws_admin') {
            user.awsRole = 'arn:aws:iam::' + context.clientMetadata.aws_account_number + ':role/auth0-admin,arn:aws:iam::' + context.clientMetadata.aws_account_number + ':saml-provider/auth0';
        }
        // these apply based on order. E.g., greatest access first and then once set following matches are ignored
        // so that users who are members of more than once group aren't overridden
        if (role === 'feedyard/aws_readonly' && !('awsRole' in user)){
            user.awsRole = 'arn:aws:iam::' + context.clientMetadata.aws_account_number + ':role/auth0-readonly,arn:aws:iam::' + context.clientMetadata.aws_account_number + ':saml-provider/auth0';
        }
    });

    user.awsRoleSession = user.nickname;
    context.samlConfiguration.mappings = {
        'https://aws.amazon.com/SAML/Attributes/Role': 'awsRole',
        'https://aws.amazon.com/SAML/Attributes/RoleSessionName': 'awsRoleSession'
    };
    callback(null, user, context);
}