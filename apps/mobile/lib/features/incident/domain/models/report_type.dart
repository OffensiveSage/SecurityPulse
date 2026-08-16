/// Enums for incident reporting.
///
/// [ReportType] defines the 9 categories of incidents an employee can report.
/// [IncidentSeverity] is the employee's self-assessed severity.
/// [IncidentStatus] tracks the lifecycle of a report.
/// [DeviceType] and [DataClassification] are used in conditional form fields.
library;

/// Category of incident being reported.
enum ReportType {
  suspiciousEmail(
    'suspicious_email',
    'Suspicious Email',
    'Received a phishing or spoofed email',
  ),
  suspiciousLink(
    'suspicious_link',
    'Suspicious Link',
    'Encountered a suspicious URL or link',
  ),
  unauthorizedAccess(
    'unauthorized_access',
    'Unauthorized Access',
    'Detected unauthorized system access',
  ),
  dataExposure(
    'data_exposure',
    'Data Exposure',
    'Discovered exposed or leaked data',
  ),
  lostDevice(
    'lost_device',
    'Lost Device',
    'Lost a company device',
  ),
  socialEngineering(
    'social_engineering',
    'Social Engineering',
    'Targeted by social engineering',
  ),
  malwareWarning(
    'malware_warning',
    'Malware Warning',
    'Received a malware alert',
  ),
  physicalSecurity(
    'physical_security',
    'Physical Security',
    'Observed a physical security issue',
  ),
  other(
    'other',
    'Other',
    'Other security concern',
  );

  const ReportType(this.apiValue, this.displayName, this.description);

  /// The value sent to and received from the API.
  final String apiValue;

  /// Human-readable display name.
  final String displayName;

  /// Short description for the form dropdown.
  final String description;

  /// Parse from API string value.
  static ReportType fromApi(String value) {
    return ReportType.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => ReportType.other,
    );
  }
}

/// Self-assessed severity of the incident.
enum IncidentSeverity {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  critical('critical', 'Critical');

  const IncidentSeverity(this.apiValue, this.displayName);
  final String apiValue;
  final String displayName;

  static IncidentSeverity fromApi(String value) {
    return IncidentSeverity.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => IncidentSeverity.low,
    );
  }
}

/// Lifecycle status of an incident report.
enum IncidentStatus {
  submitted('submitted', 'Submitted'),
  acknowledged('acknowledged', 'Acknowledged'),
  investigating('investigating', 'Investigating'),
  resolved('resolved', 'Resolved'),
  closed('closed', 'Closed');

  const IncidentStatus(this.apiValue, this.displayName);
  final String apiValue;
  final String displayName;

  static IncidentStatus fromApi(String value) {
    return IncidentStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => IncidentStatus.submitted,
    );
  }
}

/// Device type for lost device reports.
enum DeviceType {
  laptop('laptop', 'Laptop'),
  phone('phone', 'Phone'),
  tablet('tablet', 'Tablet'),
  usbDrive('usb_drive', 'USB Drive'),
  other('other', 'Other');

  const DeviceType(this.apiValue, this.displayName);
  final String apiValue;
  final String displayName;

  static DeviceType fromApi(String value) {
    return DeviceType.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => DeviceType.other,
    );
  }
}

/// Data classification for data exposure reports.
enum DataClassification {
  publicData('public', 'Public'),
  internalData('internal', 'Internal'),
  confidential('confidential', 'Confidential'),
  restricted('restricted', 'Restricted');

  const DataClassification(this.apiValue, this.displayName);
  final String apiValue;
  final String displayName;

  static DataClassification fromApi(String value) {
    return DataClassification.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => DataClassification.publicData,
    );
  }
}
