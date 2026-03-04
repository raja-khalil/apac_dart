import 'package:apac_backend/src/config/env.dart';
import 'package:apac_backend/src/modules/auth/services/email_sender.dart';
import 'package:mailer/mailer.dart' as ml;
import 'package:mailer/smtp_server.dart' as ml;

class SmtpEmailSender implements IEmailSender {
  SmtpEmailSender();

  @override
  Future<bool> send({
    required String toEmail,
    required String subject,
    required String text,
    String? html,
  }) async {
    if (!EnvConfig.smtpConfigured) {
      return false;
    }

    final server = ml.SmtpServer(
      EnvConfig.smtpHost,
      port: EnvConfig.smtpPort,
      username: EnvConfig.smtpUser,
      password: EnvConfig.smtpPassword,
      allowInsecure: EnvConfig.smtpAllowInsecure,
      ssl: EnvConfig.smtpUseSsl,
    );

    final message = ml.Message()
      ..from = ml.Address(EnvConfig.smtpFromEmail, EnvConfig.smtpFromName)
      ..recipients = [toEmail]
      ..subject = subject
      ..text = text;

    if (html != null && html.trim().isNotEmpty) {
      message.html = html;
    }

    await ml.send(message, server);
    return true;
  }
}
