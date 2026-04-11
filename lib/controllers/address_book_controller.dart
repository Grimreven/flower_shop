import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/user.dart';
import '../models/user_address.dart';
import 'auth_controller.dart';

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

    final bool hasSelected =
    addresses.any((a) => a.id == selectedAddressId.value);

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

  UserAddress? get primaryAddress {
    if (addresses.isEmpty) {
      return null;
    }

    try {
      return addresses.firstWhere((a) => a.isPrimary);
    } catch (_) {
      return addresses.first;
    }
  }

  void selectAddress(int id) {
    selectedAddressId.value = id;
  }

  Future<void> addAddress(UserAddress address) async {
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
    _ensureSelection();
    saveAddresses();
    await _syncProfileAddressWithPrimary();
  }

  Future<void> removeAddress(int id) async {
    final UserAddress? removing =
    addresses.firstWhereOrNull((a) => a.id == id);

    if (removing == null) {
      return;
    }

    addresses.removeWhere((a) => a.id == id);

    if (removing.isPrimary && addresses.isNotEmpty) {
      final UserAddress first = addresses.first;
      addresses[0] = first.copyWith(isPrimary: true);
    }

    _ensurePrimaryRules();
    _ensureSelection();
    saveAddresses();
    await _syncProfileAddressWithPrimary();
  }

  Future<void> setPrimary(int id) async {
    final List<UserAddress> updated = addresses
        .map((a) => a.copyWith(isPrimary: a.id == id))
        .toList();

    addresses.assignAll(updated);
    selectedAddressId.value = id;

    _ensurePrimaryRules();
    _ensureSelection();
    saveAddresses();
    await _syncProfileAddressWithPrimary();
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

    _ensurePrimaryRules();
    _ensureSelection();
    saveAddresses();
  }

  Future<void> _syncProfileAddressWithPrimary() async {
    final User? currentUser = authController.user.value;
    if (currentUser == null) {
      return;
    }

    final UserAddress? primary = primaryAddress;
    final String newProfileAddress = primary?.fullAddress.trim() ?? '';

    final String currentProfileAddress = currentUser.address?.trim() ?? '';
    if (currentProfileAddress == newProfileAddress) {
      return;
    }

    await authController.updateProfile(
      currentUser.copyWith(address: newProfileAddress),
    );
  }
}