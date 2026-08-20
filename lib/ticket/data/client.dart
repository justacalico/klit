// SPDX-License-Identifier: AGPL-3.0

import 'package:dio/dio.dart';
import 'package:kilt/ticket/ticket.dart';

class TicketClient {
  TicketClient({required this.dio});

  final Dio dio;

  Future<void> create({
    required TicketType type,
    required int item,
    required String reason,
    PostReportType? postReportType,
  }) {
    return dio.post(
      '/tickets',
      queryParameters: {
        'ticket[qtype]': type.id,
        'ticket[disp_id]': item,
        'ticket[reason]': reason,
        'ticket[report_reason]': ?postReportType,
      },
      options: Options(validateStatus: (status) => status == 302),
    );
  }
}
