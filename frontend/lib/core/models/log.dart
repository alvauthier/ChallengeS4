class Log {
  final DateTime time;
  final String? level;
  final String? prefix;
  final String? message;
  final String? remoteIp;
  final String? host;
  final String? method;
  final String? uri;
  final String? userAgent;
  final int? status;
  final int? latency;
  final String? latencyHuman;
  final int? bytesIn;
  final int? bytesOut;
  final String? error;

  Log({
    required this.time,
    this.level,
    this.prefix,
    this.message,
    this.remoteIp,
    this.host,
    this.method,
    this.uri,
    this.userAgent,
    this.status,
    this.latency,
    this.latencyHuman,
    this.bytesIn,
    this.bytesOut,
    this.error,
  });

  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      time: DateTime.parse(json['time']),
      level: json['level'],
      prefix: json['prefix'],
      message: json['message'],
      remoteIp: json['remote_ip'],
      host: json['host'],
      method: json['method'],
      uri: json['uri'],
      userAgent: json['user_agent'],
      status: json['status'],
      latency: json['latency'],
      latencyHuman: json['latency_human'],
      bytesIn: json['bytes_in'],
      bytesOut: json['bytes_out'],
      error: json['error'],
    );
  }
}
