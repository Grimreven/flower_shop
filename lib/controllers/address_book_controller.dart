import 'package:get/get.dart';

import '../api/server_api_service.dart';
import '../models/user_address.dart';

class AddressBookController extends GetxController {
  final RxList<UserAddress> addresses = <UserAddress>[].obs;
  final RxnInt selectedAddressId = RxnInt();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    try {
      isLoading.value = true;

      final List<Map<String, dynamic>> data =
      await ServerApiService.getAddresses();

      final List<UserAddress> parsed =
      data.map(UserAddress.fromJson).toList();

      addresses.assignAll(parsed);
      _ensureSelection();
    } catch (_) {
      addresses.clear();
      selectedAddressId.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  UserAddress? get selectedAddress {
    final int? id = selectedAddressId.value;

    if (id == null) {
      return primaryAddress;
    }

    return addresses.firstWhereOrNull((UserAddress item) => item.id == id) ??
        primaryAddress;
  }

  UserAddress? get primaryAddress {
    return addresses.firstWhereOrNull((UserAddress item) => item.isPrimary) ??
        addresses.firstOrNull;
  }

  void selectAddress(int id) {
    selectedAddressId.value = id;
  }

  Future<void> addAddress(UserAddress address) async {
    final Map<String, dynamic> created =
    await ServerApiService.createAddress(address.toApiJson());

    final UserAddress newAddress = UserAddress.fromJson(created);

    selectedAddressId.value = newAddress.id;

    await loadAddresses();
  }

  Future<void> updateAddress(UserAddress address) async {
    final Map<String, dynamic> updated =
    await ServerApiService.updateAddress(address.id, address.toApiJson());

    final UserAddress newAddress = UserAddress.fromJson(updated);

    selectedAddressId.value = newAddress.id;

    await loadAddresses();
  }

  Future<void> removeAddress(int id) async {
    await ServerApiService.deleteAddress(id);

    if (selectedAddressId.value == id) {
      selectedAddressId.value = null;
    }

    await loadAddresses();
  }

  Future<void> setPrimary(int id) async {
    final UserAddress? address =
    addresses.firstWhereOrNull((UserAddress item) => item.id == id);

    if (address == null) {
      return;
    }

    await updateAddress(address.copyWith(isPrimary: true));
  }

  Future<void> setPrimaryAddress(int id) async {
    await setPrimary(id);
  }

  void syncPrimaryFromProfileIfNeeded() {}

  void clear() {
    addresses.clear();
    selectedAddressId.value = null;
  }

  void _ensureSelection() {
    if (addresses.isEmpty) {
      selectedAddressId.value = null;
      return;
    }

    final int? current = selectedAddressId.value;

    if (current != null &&
        addresses.any((UserAddress item) => item.id == current)) {
      return;
    }

    selectedAddressId.value = primaryAddress?.id ?? addresses.first.id;
  }
}