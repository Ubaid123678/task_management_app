import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/models/task.dart';

class ExportService {
  ExportService._internal();

  static final ExportService instance = ExportService._internal();

  Future<Uint8List> createCsvReportBytes(List<Task> tasks) async {
    final rows = <List<String>>[
      <String>[
        'ID',
        'Title',
        'Description',
        'Due Date',
        'Completed',
        'Repeat Type',
        'Repeat Days',
        'Repeat Interval',
        'Progress %',
        'Created At',
        'Updated At',
      ],
    ];

    for (final task in tasks) {
      rows.add(<String>[
        (task.id ?? '').toString(),
        task.title,
        task.description ?? '',
        _formatDate(task.dueDateTime),
        task.isCompleted ? 'Yes' : 'No',
        task.repeatType.name,
        task.repeatDays.join(','),
        task.repeatInterval?.toString() ?? '',
        (task.progress * 100).toStringAsFixed(0),
        _formatDate(task.createdAt),
        _formatDate(task.updatedAt),
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    return Uint8List.fromList(utf8.encode(csv));
  }

  Future<Uint8List> createPdfReportBytes(List<Task> tasks) async {
    final now = DateTime.now();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          pageFormat: PdfPageFormat.a4,
        ),
        build: (context) {
          return [
            pw.Text(
              'Task Management Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}',
            ),
            pw.SizedBox(height: 12),
            pw.Text('Total Tasks: ${tasks.length}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue100,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(1.6),
                2: const pw.FlexColumnWidth(1.3),
                3: const pw.FlexColumnWidth(1.0),
              },
              headers: const ['Title', 'Due', 'Repeat', 'Progress'],
              data: tasks
                  .map(
                    (task) => [
                      task.title,
                      _formatDate(task.dueDateTime),
                      task.repeatType.name,
                      '${(task.progress * 100).toStringAsFixed(0)}%',
                    ],
                  )
                  .toList(growable: false),
            ),
          ];
        },
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  Future<void> exportAndShareCsv(List<Task> tasks) async {
    final bytes = await createCsvReportBytes(tasks);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: 'text/csv', name: 'task_report.csv'),
        ],
        subject: 'Task Report (CSV)',
        text: 'Attached is the task report in CSV format.',
      ),
    );
  }

  Future<void> exportAndSharePdf(List<Task> tasks) async {
    final bytes = await createPdfReportBytes(tasks);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/pdf',
            name: 'task_report.pdf',
          ),
        ],
        subject: 'Task Report (PDF)',
        text: 'Attached is the task report in PDF format.',
      ),
    );
  }

  Future<void> shareByEmail(List<Task> tasks) async {
    final csvBytes = await createCsvReportBytes(tasks);

    final completed = tasks.where((task) => task.isCompleted).length;
    final pending = tasks.length - completed;

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            csvBytes,
            mimeType: 'text/csv',
            name: 'task_report.csv',
          ),
        ],
        subject: 'Task Management Summary',
        text:
            'Task Summary\n\nTotal: ${tasks.length}\nCompleted: $completed\nPending: $pending\n\nCSV report attached.\nChoose your email app to send.',
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(value);
  }
}
