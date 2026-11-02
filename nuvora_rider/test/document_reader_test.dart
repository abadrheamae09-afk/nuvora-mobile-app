import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora_app/core/ocr/document_reader.dart';

void main() {
  test("driver's license text fills the license fields", () {
    final fields = DocumentReader.readLicenseText([
      'REPUBLIC OF THE PHILIPPINES',
      'DEPARTMENT OF TRANSPORTATION',
      'LAND TRANSPORTATION OFFICE',
      "DRIVER'S LICENSE",
      'DELA CRUZ, JUAN SANTOS',
      'License No. N01-23-456789',
      'Expiration Date 2029/08/12',
      'Date of Birth 1996/02/03',
      'Address 123 SAMPAGUITA ST BRGY. SAN ISIDRO, STA. CRUZ, LAGUNA',
      'Nationality FILIPINO',
      'Agency Code B',
    ]);

    expect(fields['dlLast'], 'Dela Cruz');
    expect(fields['dlFirst'], 'Juan');
    expect(fields['dlMiddle'], 'Santos');
    expect(fields['dlLicenseNo'], 'N01-23-456789');
    expect(fields['dlExpiration'], '08/12/2029');
    expect(fields['dlNationality'], 'Filipino');
    expect(fields['dlAddress'], contains('123 SAMPAGUITA ST'));
    expect(fields['dlCode'], licenseCodeOptions[2]);
  });

  test('a motorcycle license code selects the A option', () {
    final fields = DocumentReader.readLicenseText([
      'License No. A12-34-567890',
      'Agency Code A',
    ]);

    expect(fields['dlLicenseNo'], 'A12-34-567890');
    expect(fields['dlCode'], licenseCodeOptions[0]);
  });

  test('OR / CR text fills the registration and vehicle fields', () {
    final fields = DocumentReader.readOrCrText([
      'REPUBLIC OF THE PHILIPPINES',
      'CERTIFICATE OF REGISTRATION',
      'MV FILE NO. 1234-5678901234',
      'PLATE NO. ABC 1234',
      'MAKE HONDA',
      'SERIES CLICK 125I',
      'BODY TYPE MOTORCYCLE',
      'YEAR MODEL 2022',
      'COLOR BLACK',
      'ENGINE NO. JC61E1234567',
      'CHASSIS NO. MH1JC6112NK123456',
      'REGISTERED OWNER DELA CRUZ, JUAN SANTOS',
      "OWNER'S ADDRESS 123 SAMPAGUITA ST, STA. CRUZ, LAGUNA",
      'VALID UNTIL 2027/05/12',
    ]);

    expect(fields['mvFile'], '1234-5678901234');
    expect(fields['orPlate'], 'ABC 1234');
    expect(fields['plate'], 'ABC 1234');
    expect(fields['make'], 'Honda');
    expect(fields['series'], 'CLICK 125I');
    expect(fields['body'], 'Motorcycle');
    expect(fields['vehicleType'], 'Motorcycle');
    expect(fields['year'], '2022');
    expect(fields['color'], 'Black');
    expect(fields['engine'], 'JC61E1234567');
    expect(fields['chassis'], 'MH1JC6112NK123456');
    expect(fields['owner'], 'Dela Cruz, Juan Santos');
    expect(fields['ownerAddress'], contains('123 SAMPAGUITA ST'));
    expect(fields['regExp'], '05/12/2027');
  });

  test('unreadable text yields no fields instead of wrong ones', () {
    expect(DocumentReader.readLicenseText(['', '   ']), isEmpty);
    expect(DocumentReader.readOrCrText(['BLURRY PHOTO']), isEmpty);
  });
}
