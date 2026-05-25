const axios = require('axios');
const qs = require('qs');

const RAJAONGKIR_API_KEY  = process.env.RAJAONGKIR_API_KEY;
const RAJAONGKIR_BASE_URL = process.env.RAJAONGKIR_BASE_URL;

const MOCK_CITIES = [
    { id: '36', label: 'Jakarta Barat, DKI Jakarta', province_name: 'DKI Jakarta', city_name: 'Jakarta Barat', district_name: 'Grogol', zip_code: '11450' },
    { id: '37', label: 'Jakarta Pusat, DKI Jakarta', province_name: 'DKI Jakarta', city_name: 'Jakarta Pusat', district_name: 'Gambir', zip_code: '10110' },
    { id: '38', label: 'Jakarta Selatan, DKI Jakarta', province_name: 'DKI Jakarta', city_name: 'Jakarta Selatan', district_name: 'Kebayoran Baru', zip_code: '12110' },
    { id: '39', label: 'Jakarta Timur, DKI Jakarta', province_name: 'DKI Jakarta', city_name: 'Jakarta Timur', district_name: 'Jatinegara', zip_code: '13310' },
    { id: '40', label: 'Jakarta Utara, DKI Jakarta', province_name: 'DKI Jakarta', city_name: 'Jakarta Utara', district_name: 'Tanjung Priok', zip_code: '14310' },
    { id: '46', label: 'Bandung, Jawa Barat', province_name: 'Jawa Barat', city_name: 'Bandung', district_name: 'Coblong', zip_code: '40135' },
    { id: '120', label: 'Surabaya, Jawa Timur', province_name: 'Jawa Timur', city_name: 'Surabaya', district_name: 'Gubeng', zip_code: '60281' },
    { id: '9', label: 'Medan, Sumatera Utara', province_name: 'Sumatera Utara', city_name: 'Medan', district_name: 'Medan Baru', zip_code: '20152' },
    { id: '267', label: 'Makassar, Sulawesi Selatan', province_name: 'Sulawesi Selatan', city_name: 'Makassar', district_name: 'Rappocini', zip_code: '90222' },
    { id: '124', label: 'Yogyakarta, DI Yogyakarta', province_name: 'DI Yogyakarta', city_name: 'Yogyakarta', district_name: 'Umbulharjo', zip_code: '55161' },
    { id: '41', label: 'Bogor, Jawa Barat', province_name: 'Jawa Barat', city_name: 'Bogor', district_name: 'Bogor Tengah', zip_code: '16122' },
    { id: '42', label: 'Bekasi, Jawa Barat', province_name: 'Jawa Barat', city_name: 'Bekasi', district_name: 'Bekasi Barat', zip_code: '17133' },
    { id: '43', label: 'Depok, Jawa Barat', province_name: 'Jawa Barat', city_name: 'Depok', district_name: 'Pancoran Mas', zip_code: '16436' },
    { id: '44', label: 'Tangerang, Banten', province_name: 'Banten', city_name: 'Tangerang', district_name: 'Tangerang', zip_code: '15111' },
    { id: '45', label: 'Tangerang Selatan, Banten', province_name: 'Banten', city_name: 'Tangerang Selatan', district_name: 'Serpong', zip_code: '15310' }
];

function getMockShippingCosts(payload) {
    const { courier = 'jne:jnt:sicepat:anteraja:pos', weight = 1000 } = payload;
    const weightKg = Math.max(1, Math.ceil(Number(weight) / 1000));
    const courierList = courier.toLowerCase().split(':');
    const mockServices = [];
    
    const allServices = {
        jne: [
            { service: 'REG', description: 'Layanan Reguler', baseCost: 15000, etd: '2-3 hari', name: 'Jalur Nugraha Ekakurir (JNE)' },
            { service: 'YES', description: 'Yakin Esok Sampai', baseCost: 30000, etd: '1-1 hari', name: 'Jalur Nugraha Ekakurir (JNE)' }
        ],
        jnt: [
            { service: 'EZ', description: 'Regular Service', baseCost: 12000, etd: '2-3 hari', name: 'J&T Express' },
            { service: 'JSD', description: 'Sameday Service', baseCost: 25000, etd: '1-1 hari', name: 'J&T Express' }
        ],
        sicepat: [
            { service: 'REG', description: 'Regular reguler', baseCost: 13000, etd: '2-3 hari', name: 'SiCepat Ekspres' },
            { service: 'BEST', description: 'Besok Sampai Tujuan', baseCost: 28000, etd: '1-1 hari', name: 'SiCepat Ekspres' }
        ],
        anteraja: [
            { service: 'REG', description: 'Regular Service', baseCost: 13000, etd: '2-3 hari', name: 'AnterAja' },
            { service: 'SD', description: 'Same Day', baseCost: 26000, etd: '1-1 hari', name: 'AnterAja' }
        ],
        pos: [
            { service: 'KILAT KHUSUS', description: 'Pos Kilat Khusus', baseCost: 10000, etd: '3-5 hari', name: 'POS Indonesia' },
            { service: 'EXPRESS', description: 'Pos Express', baseCost: 25000, etd: '1-2 hari', name: 'POS Indonesia' }
        ]
    };
    
    for (const c of courierList) {
        const services = allServices[c] || [
            { service: 'REG', description: 'Regular Service', baseCost: 15000, etd: '2-4 hari', name: c.toUpperCase() }
        ];
        
        for (const s of services) {
            mockServices.push({
                name: s.name,
                code: c,
                service: s.service,
                description: s.description,
                cost: s.baseCost * weightKg,
                etd: s.etd
            });
        }
    }
    
    return mockServices;
}

const rajaongkirGet = async (path, params = {}) => {
    try {
        const response = await axios.get(`${RAJAONGKIR_BASE_URL}${path}`, {
            headers: { key: RAJAONGKIR_API_KEY },
            params,
            validateStatus: (status) => status < 500, // Handle 404 manually
        });
        const { meta, data } = response.data;
        if (meta.code === 404) return []; // If not found, return empty array
        if (meta.code !== 200) throw new Error(meta.message);
        return data;
    } catch (err) {
        console.warn('️ RajaOngkir GET failed, using mock cities fallback:', err.message);
        const searchQuery = params.search || '';
        return MOCK_CITIES.filter(c => c.label.toLowerCase().includes(searchQuery.toLowerCase().trim()));
    }
};

const rajaongkirPost = async (path, payload = {}) => {
    try {
        const stringified = qs.stringify(payload);
        const response = await axios.post(
            `${RAJAONGKIR_BASE_URL}${path}`,
            stringified,
            {
                headers: {
                    key: RAJAONGKIR_API_KEY,
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
            }
        );
        const { meta, data } = response.data;
        if (meta.code !== 200) throw new Error(meta.message);
        return data;
    } catch (err) {
        console.warn('️ RajaOngkir POST failed, using mock costs fallback:', err.message);
        if (path.includes('/calculate/')) {
            return getMockShippingCosts(payload);
        }
        throw err;
    }
};

module.exports = { rajaongkirGet, rajaongkirPost };