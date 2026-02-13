import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:zindeai_app/services/algo_client.dart';
import 'package:zindeai_app/services/errors.dart';
import 'package:zindeai_app/services/models/swap_models.dart';

import 'algo_client_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  group('AlgoClient', () {
    late MockDio mockDio;
    late AlgoClient algoClient;

    setUp(() {
      mockDio = MockDio();
      algoClient = AlgoClient(dio: mockDio);
    });

    group('/health', () {
      test('200 → JSON parse edilir', () async {
        when(mockDio.get('/health')).thenAnswer(
          (_) async => Response(
            data: {'status': 'healthy', 'version': '8.3.1'},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/health'),
          ),
        );

        final result = await algoClient.health();

        expect(result, {'status': 'healthy', 'version': '8.3.1'});
        verify(mockDio.get('/health')).called(1);
      });
    });

    group('/get-alternatives', () {
      test('200 → 2 alternatif parse edilir', () async {
        final responseData = {
          'alternatives': [
            {
              'yemek_id': 'k2',
              'ad': 'Yumurtalı Sandviç',
              'porsiyon': 'medium',
              'porsiyon_g': 150.0,
              'kalori': 320.0,
              'protein': 14.0,
              'karb': 35.0,
              'yag': 12.0,
            },
            {
              'yemek_id': 'k3',
              'ad': 'Avokadolu Tost',
              'porsiyon': 'medium',
              'porsiyon_g': 180.0,
              'kalori': 396.0,
              'protein': 9.0,
              'karb': 36.0,
              'yag': 25.2,
            },
          ],
          'count': 2,
          'tolerance': '±15%'
        };

        when(mockDio.post('/get-alternatives', data: anyNamed('data')))
            .thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/get-alternatives'),
          ),
        );

        final request = SwapAlternativesRequest(
          yemekId: 'k1',
          ogunSlot: 'kahvalti',
          diyetTipi: 'normal',
          alerjenler: [],
        );

        final result = await algoClient.getAlternatives(request);

        expect(result.alternatives.length, 2);
        expect(result.count, 2);
        expect(result.tolerance, '±15%');
        expect(result.alternatives[0].yemekId, 'k2');
        expect(result.alternatives[0].ad, 'Yumurtalı Sandviç');
        expect(result.alternatives[1].yemekId, 'k3');
        expect(result.alternatives[1].ad, 'Avokadolu Tost');
        verify(mockDio.post('/get-alternatives', data: anyNamed('data')))
            .called(1);
      });

      test('422 INSUFFICIENT_POOL → InsufficientPoolException fırlatılır',
          () async {
        final errorData = {
          'code': 'INSUFFICIENT_POOL',
          'message': 'Bu filtrelere uygun hiç alternatif yok',
          'filters': {
            'meal_type': 'kahvalti',
            'diet': 'vegan',
            'allergens': []
          },
          'suggestion': 'Filtrelerinizi gevşetin veya başka slot deneyin'
        };

        when(mockDio.post('/get-alternatives', data: anyNamed('data')))
            .thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/get-alternatives'),
            response: Response(
              data: errorData,
              statusCode: 422,
              requestOptions: RequestOptions(path: '/get-alternatives'),
            ),
          ),
        );

        final request = SwapAlternativesRequest(
          yemekId: 'k1',
          ogunSlot: 'kahvalti',
          diyetTipi: 'vegan',
          alerjenler: [],
        );

        expect(
          () => algoClient.getAlternatives(request),
          throwsA(isA<InsufficientPoolException>().having(
            (e) => e.message,
            'message',
            'Bu filtrelere uygun hiç alternatif yok',
          )),
        );
      });

      test('Timeout → NetworkException fırlatılır', () async {
        when(mockDio.post('/get-alternatives', data: anyNamed('data')))
            .thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/get-alternatives'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        final request = SwapAlternativesRequest(
          yemekId: 'k1',
          ogunSlot: 'kahvalti',
        );

        expect(
          () => algoClient.getAlternatives(request),
          throwsA(isA<NetworkException>()),
        );
      }, timeout: const Timeout(Duration(seconds: 10)));

      test('422 → retry YAPILMAZ (1 deneme)', () async {
        final errorData = {
          'code': 'INSUFFICIENT_POOL',
          'message': 'Havuz yetersiz',
        };

        when(mockDio.post('/get-alternatives', data: anyNamed('data')))
            .thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/get-alternatives'),
            response: Response(
              data: errorData,
              statusCode: 422,
              requestOptions: RequestOptions(path: '/get-alternatives'),
            ),
          ),
        );

        final request = SwapAlternativesRequest(
          yemekId: 'k1',
          ogunSlot: 'kahvalti',
        );

        expect(
          () => algoClient.getAlternatives(request),
          throwsA(isA<InsufficientPoolException>()),
        );

        // 422 için retry yok, sadece 1 deneme
        verify(mockDio.post('/get-alternatives', data: anyNamed('data')))
            .called(1);
      });
    });
  });
}
