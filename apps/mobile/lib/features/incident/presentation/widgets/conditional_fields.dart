/// Conditional form fields based on report type.
///
/// Renders type-specific additional fields:
/// - suspicious_email/suspicious_link: sender/URL text field
/// - unauthorized_access: system affected text field
/// - lost_device: device type dropdown + last known location
/// - data_exposure: data classification dropdown
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/models/report_type.dart';

/// Renders conditional fields based on the selected report type.
class ConditionalFields extends StatelessWidget {
  const ConditionalFields({
    required this.reportType,
    required this.metadataFields,
    required this.onFieldChanged,
    super.key,
  });

  final ReportType? reportType;
  final Map<String, dynamic> metadataFields;
  final void Function(String key, dynamic value) onFieldChanged;

  @override
  Widget build(BuildContext context) {
    if (reportType == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return switch (reportType!) {
      ReportType.suspiciousEmail ||
      ReportType.suspiciousLink =>
        _buildTextField(
          label: l10n.incidentReportSenderUrlLabel,
          key: 'sender_or_url',
          value: metadataFields['sender_or_url'] as String? ?? '',
        ),
      ReportType.unauthorizedAccess => _buildTextField(
          label: l10n.incidentReportSystemAffectedLabel,
          key: 'system_affected',
          value: metadataFields['system_affected'] as String? ?? '',
        ),
      ReportType.lostDevice => Column(
          children: [
            _buildDeviceTypeDropdown(context, l10n),
            const SizedBox(height: 16),
            _buildTextField(
              label: l10n.incidentReportLastLocationLabel,
              key: 'last_known_location',
              value: metadataFields['last_known_location'] as String? ?? '',
            ),
          ],
        ),
      ReportType.dataExposure =>
        _buildDataClassificationDropdown(context, l10n),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildTextField({
    required String label,
    required String key,
    required String value,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) => onFieldChanged(key, v),
    );
  }

  Widget _buildDeviceTypeDropdown(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final currentValue = metadataFields['device_type'] as String?;
    DeviceType? selected;
    if (currentValue != null) {
      selected = DeviceType.fromApi(currentValue);
    }

    return DropdownButtonFormField<DeviceType>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: l10n.incidentReportDeviceTypeLabel,
        border: const OutlineInputBorder(),
      ),
      items: DeviceType.values.map((type) {
        return DropdownMenuItem<DeviceType>(
          value: type,
          child: Text(type.displayName),
        );
      }).toList(),
      onChanged: (type) {
        if (type != null) {
          onFieldChanged('device_type', type.apiValue);
        }
      },
    );
  }

  Widget _buildDataClassificationDropdown(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final currentValue = metadataFields['data_classification'] as String?;
    DataClassification? selected;
    if (currentValue != null) {
      selected = DataClassification.fromApi(currentValue);
    }

    return DropdownButtonFormField<DataClassification>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: l10n.incidentReportDataClassificationLabel,
        border: const OutlineInputBorder(),
      ),
      items: DataClassification.values.map((cls) {
        return DropdownMenuItem<DataClassification>(
          value: cls,
          child: Text(cls.displayName),
        );
      }).toList(),
      onChanged: (cls) {
        if (cls != null) {
          onFieldChanged('data_classification', cls.apiValue);
        }
      },
    );
  }
}
