abstract class IEmailSender {
  Future<bool> send({
    required String toEmail,
    required String subject,
    required String text,
    String? html,
  });
}

