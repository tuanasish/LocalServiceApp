import 'package:flutter/foundation.dart';

/// Notification Model
/// Maps to `notifications` table in Supabase
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isRead => read;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String? ?? 'system_alert'),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      read: json['read'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toDbString(),
      'title': title,
      'body': body,
      'data': data,
      'read': read,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, read: $read)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationModel &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.title == title &&
        other.body == body &&
        mapEquals(other.data, data) &&
        other.read == read &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      type,
      title,
      body,
      data,
      read,
      createdAt,
      expiresAt,
    );
  }
}

/// Notification Type Enum
enum NotificationType {
  orderAssigned,
  orderCanceled,
  orderCompleted,
  approvalApproved,
  approvalRejected,
  paymentReceived,
  announcement,
  systemAlert;

  String toDbString() {
    switch (this) {
      case NotificationType.orderAssigned:
        return 'order_assigned';
      case NotificationType.orderCanceled:
        return 'order_canceled';
      case NotificationType.orderCompleted:
        return 'order_completed';
      case NotificationType.approvalApproved:
        return 'approval_approved';
      case NotificationType.approvalRejected:
        return 'approval_rejected';
      case NotificationType.paymentReceived:
        return 'payment_received';
      case NotificationType.announcement:
        return 'announcement';
      case NotificationType.systemAlert:
        return 'system_alert';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'order_assigned':
        return NotificationType.orderAssigned;
      case 'order_canceled':
        return NotificationType.orderCanceled;
      case 'order_completed':
        return NotificationType.orderCompleted;
      case 'approval_approved':
        return NotificationType.approvalApproved;
      case 'approval_rejected':
        return NotificationType.approvalRejected;
      case 'payment_received':
        return NotificationType.paymentReceived;
      case 'announcement':
        return NotificationType.announcement;
      case 'system_alert':
        return NotificationType.systemAlert;
      default:
        throw ArgumentError('Unknown notification type: $value');
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.orderAssigned:
        return 'Đơn hàng mới';
      case NotificationType.orderCanceled:
        return 'Đơn hàng hủy';
      case NotificationType.orderCompleted:
        return 'Đơn hoàn thành';
      case NotificationType.approvalApproved:
        return 'Tài khoản duyệt';
      case NotificationType.approvalRejected:
        return 'Tài khoản từ chối';
      case NotificationType.paymentReceived:
        return 'Thanh toán';
      case NotificationType.announcement:
        return 'Thông báo';
      case NotificationType.systemAlert:
        return 'Cảnh báo hệ thống';
    }
  }
}
