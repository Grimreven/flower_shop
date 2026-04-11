import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../controllers/auth_controller.dart';
import '../models/user_address.dart';

class AddressBookController extends GetxController {
  static const String _storageKeyPrefix = 'saved_addresses_user_';

  final AuthController authController = Get.find<AuthController>();
  final GetStorage _storage = GetStorage();

  final RxList<UserAddress> addresses = <UserAddress>[].obs;
  final RxnInt selectedAddressId = RxnInt();

  String get _storageKey {
    final int userId = authController.user.value?.id ?? 0;
    return '$_storageKeyPrefix$userId';
  }

  @override
  void onInit() {
    super.onInit();
    loadAddresses();
  }

  void loadAddresses() {
    final List<dynamic>? raw = _storage.read<List<dynamic>>(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      final List<UserAddress> parsed = raw
          .map(
            (e) => UserAddress.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
      )
          .toList();

      addresses.assignAll(parsed);
    } else {
      _seedPrimaryAddressFromProfile();
    }

    _ensurePrimaryRules();
    _ensureSelection();
    saveAddresses();
  }

  void _seedPrimaryAddressFromProfile() {
    final String profileAddress =
        authController.user.value?.address?.trim() ?? '';

    if (profileAddress.isEmpty) {
      addresses.clear();
      return;
    }

    addresses.assignAll([
      UserAddress(
        id: 1,
        title: 'Основной',
        address: profileAddress,
        isPrimary: true,
      ),
    ]);
  }

  void _ensurePrimaryRules() {
    if (addresses.isEmpty) {
      return;
    }

    bool hasPrimary = addresses.any((a) => a.isPrimary);

    if (!hasPrimary) {
      final UserAddress first = addresses.first;
      addresses[0] = first.copyWith(isPrimary: true);
      hasPrimary = true;
    }

    bool primaryFound = false;
    final List<UserAddress> normalized = addresses.map((a) {
      if (a.isPrimary && !primaryFound) {
        primaryFound = true;
        return a;
      }
      if (a.isPrimary && primaryFound) {
        return a.copyWith(isPrimary: false);
      }
      return a;
    }).toList();

    addresses.assignAll(normalized);
  }

  void _ensureSelection() {
    if (addresses.isEmpty) {
      selectedAddressId.value = null;
      return;
    }

    final bool hasSelected = addresses.any((a) => a.id == selectedAddressId.value);
    if (hasSelected) {
      return;
    }

    final UserAddress primary = addresses.firstWhere(
          (a) => a.isPrimary,
      orElse: () => addresses.first,
    );

    selectedAddressId.value = primary.id;
  }

  void saveAddresses() {
    _storage.write(
      _storageKey,
      addresses.map((e) => e.toJson()).toList(),
    );
  }

  UserAddress? get selectedAddress {
    if (selectedAddressId.value == null) {
      return null;
    }

    try {
      return addresses.firstWhere((a) => a.id == selectedAddressId.value);
    } catch (_) {
      return null;
    }
  }

  void selectAddress(int id) {
    selectedAddressId.value = id;
  }

  void addAddress(UserAddress address) {
    final int nextId = addresses.isEmpty
        ? 1
        : addresses.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;

    final UserAddress newAddress = address.copyWith(
      id: nextId,
      isPrimary: addresses.isEmpty ? true : address.isPrimary,
    );

    if (newAddress.isPrimary) {
      final List<UserAddress> updated = addresses
          .map((a) => a.copyWith(isPrimary: false))
          .toList();
      updated.add(newAddress);
      addresses.assignAll(updated);
    } else {
      addresses.add(newAddress);
    }

    selectedAddressId.value = newAddress.id;
    _ensurePrimaryRules();
    saveAddresses();
  }

  void removeAddress(int id) {
    final UserAddress? removing = addresses.firstWhereOrNull((a) => a.id == id);
    if (removing == null) {
      return;
    }

    addresses.removeWhere((a) => a.id == id);

    if (removing.isPrimary && addresses.isNotEmpty) {
      final UserAddress first = addresses.first;
      addresses[0] = first.copyWith(isPrimary: true);
    }

    _ensureSelection();
    saveAddresses();
  }

  void setPrimary(int id) {
    final List<UserAddress> updated = addresses
        .map((a) => a.copyWith(isPrimary: a.id == id))
        .toList();

    addresses.assignAll(updated);
    selectedAddressId.value = id;
    saveAddresses();
  }

  void syncPrimaryFromProfileIfNeeded() {
    final String profileAddress =
        authController.user.value?.address?.trim() ?? '';

    if (profileAddress.isEmpty) {
      return;
    }

    if (addresses.isEmpty) {
      addresses.add(
        UserAddress(
          id: 1,
          title: 'Основной',
          address: profileAddress,
          isPrimary: true,
        ),
      );
      selectedAddressId.value = 1;
      saveAddresses();
      return;
    }

    final int primaryIndex = addresses.indexWhere((a) => a.isPrimary);
    if (primaryIndex == -1) {
      return;
    }

    final UserAddress primary = addresses[primaryIndex];
    addresses[primaryIndex] = primary.copyWith(address: profileAddress);
    saveAddresses();
  }
}