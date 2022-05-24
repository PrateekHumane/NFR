// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x11be1abeaf85ad1c9b5913b42f2b7cce1a8e6565c490cc326adb9e6d9d551486), uint256(0x20577d2b2daebbae650678210d1a9a9a83566d4b66c052ab621d7dd07062f1e7));
        vk.beta = Pairing.G2Point([uint256(0x058ece0f9eb25abe763d07927b5bf45f78016c0647978f0ae9bd5282d647f438), uint256(0x16cd5b374ce662482bf35ea2bcfa66337bdc2790d6369de7fed702f9087f90ed)], [uint256(0x07c0d089bb654804441b151c931185f8421f3511f78fd5ddf94b1503baa7c635), uint256(0x1741cb298a6afc30958de5887eea674279a025f6fdb853b3ee8c6f3705529917)]);
        vk.gamma = Pairing.G2Point([uint256(0x032d51ea5210bcf0ad8cb52ab2bbb0723deec07f73405086783c9ae4015c2905), uint256(0x1afcd1cb09659637a498a26c9df20950e76fb11af5d814293d8963fc5841260c)], [uint256(0x16c97cfc0d1135e8ed10664a692b5fe8084244b4e179d287dd11190311152265), uint256(0x273346e8297e24ab190b88117015b17cff94b8125f51854ae50bb75d262c408a)]);
        vk.delta = Pairing.G2Point([uint256(0x214aa65b645029d32dbe3df39ba070418d7d5eefdd310624f8d2868c9099dd3c), uint256(0x2ca650bdd03b2dc459398047295ef85d789e7dcb12b0ed6d1e5182f18c772fd4)], [uint256(0x101939b72361cf95e6d027fb24d129dfdaecdac64db77f0afdb0b9574255299a), uint256(0x1b3f45401c9e5ef74eeb298f028f7bd857950a75bfef7a395893abf860edae60)]);
        vk.gamma_abc = new Pairing.G1Point[](40);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x126378c680e065e647fe45f6ea0604c0481f7c3f576a45581a4ed00fea8255ca), uint256(0x2d74c167a93e584583efb8c7b3a421009d11c0b7eee07e5387705b3d55b12c3b));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x01d765219925e4e2ab38943a1ca656075f7567707b5f9aecf9fe292e99baacf0), uint256(0x245864fdefdaa35b30fb0feb5d7ccb1217b04a69b85d9758985c27b3b19cdcff));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x05f50f7d6c174998bdbc37eb2ca4dce16c7fbe19f781af2473b4997ddf78d653), uint256(0x2d6e4cfd639efde79290c867bd4388f37b61576707a2e7be90e6562787245c0d));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x209d1c5b5dda970c7f1560b61f6ebf0e16bc7030eddef0819535ebc5e4172c27), uint256(0x1f7bad5020be136e534dafc7d9402ed6295ba82691f52d3e722e8b51e06773f2));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x245bc54a83938e4bebcee1d4c13531900e08f372fe4c5210a2ff25c552d20f14), uint256(0x2005140aba50af343790b7d12bd1ff1e849c6500c03e8b41e489f16a91cd67ad));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x13f7b6d48c927182339892172620bc6982f4d9eda751a9536256b6066778cf17), uint256(0x080a7a6b4c7b2376f6cb9eda40d2df73ada5ca958673e891be1e560c0ec7c808));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2ac79868ab292bdbfca3c04ffebf359539cadacd09cf89f7ec870b6e219214be), uint256(0x10d77a6fbf46090b699a1fb8e2cdb6b7960750fcf75264a34de59cbec606bb31));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x084aedec54d7fb5e5573f770bd3061e1d740763123807478c0ec89e2213af303), uint256(0x2f06a37874c6473917822f71f960cb5cc572b55a2f5c258c3f7de80609296bc6));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2c53937223934b1cb94214759bc7cf00245f1ec23e6491a55a4111b0f3cbacce), uint256(0x13a88648c6d464fccdbfc4a883977d2c4038e88a34a5ed9b96381febf9ec7a8f));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x1a021ad6b2ef2434291c04e1cbb376a694aadd21069baf669007463bc23c430b), uint256(0x0a6b2464369262a8ca7760346bdef636ca0d90edeab8c5d1ca591ec03f1cafb1));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x10feb4701d7a0591a485832f7b9208050a5c75bf9b8d09702c98824c2f2f2b11), uint256(0x004338457a25eb3803b23a7245ebc06effefa1734f0ac304b91c67d613852c2e));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x1eb4c3c1b420b94d8e9ae6873952ced911eb021e1bc8eccef32be52946842292), uint256(0x03778350226190ed989a6a1246a554a233ae9b9063c581791c98fb56b3322095));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x0c5f42e2549ebf25ae5fcdee23859594877ce6e5667616d62cde604541d45ff5), uint256(0x1b79024a65d766f875914bf79b4779a6fe0cedae76601eb7c8f765ebf3cf54d3));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x1990a1473ee82bfb94eb05e136a407273bae0c2d7287095b72be7041a7d2cd1e), uint256(0x189f28aa865e4cf04ab2d5db434fa032f9e3d0d1b016b1cf48585a53f0cfff4e));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x155b6e09ce33cc7c7143d6daa584e22d7e7326403215d798e2f80f179af433a9), uint256(0x2e3c94a503a2997f3e27ed12768fdaaaf6626e36f5bc2bd52f02fe8ca6bd609a));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x15965471ffff3229fa33b3490370f6565500ed19c414db09aac4959c2120c9ce), uint256(0x1f0a1646a531ee329b23f01a17696bc540fdbe308569251636f9cc4a7fcd4ed7));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x0632398fbca5b6cc32ab618e0539a78f990852ad28e9a89542ce9cfa74a23969), uint256(0x2d019326d03e428bba728324a050bb0c768ed87f8f37f716f05d4aa15a2e6e94));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x14d84be3fc9c16fc9647ee24b9c9f674fa5e934e2de9b58415ce669629ce05ae), uint256(0x23eb17ef2cc4da7ca674d1c86b180be00e85e164db3de2d42df25770e037488d));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x151bd01646878644b65182741d37641531fd56b2832a361fbb4d35c40e93f65c), uint256(0x08fc0a0a5bff7b7649644013860c2ca52a52e918f389bc23c424d300b7354558));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x1c7b0338e3f3395ed720f1e5ba4447ce080e5457fd58d8eda69a0a34d91f2dd6), uint256(0x239c5c5b69415becba8966a245d512baa6b423f794e888c43fff13c3a4753a44));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x13bd080a8ee834436a697558163128971c4a6414289e8851a2186d38e9d0def9), uint256(0x20e430383a0e1a876b5c677dbda681e80e15e4303729baa1755a1e6d20808068));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x18292da1733affe18f35dff6208ba8376746cb62805e1025784ca898629462ba), uint256(0x061bcb5d31e5c8f2013095b2e7a98eeb18e204275760c35fd34db576d6a29dff));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x224b5effa5f3843a593cb30c9457c4de262ae33342379e54d3b7fd8baf4b55bf), uint256(0x173174499962000be9aa2e85aec0eaf2d3fcdb48ecd6d24bcdc0f9e8763338e2));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x0770e289904fa42cbbafeac6af7530dce3047956ba4421bf80b27d3b55cc16a2), uint256(0x1ad69fe443752c9b5622dfab3c0099cfe531791e0f18a4bb13342bcff9ba9bca));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x20037f2c9be27580cebf7d2ec6b5620cf667209e4cc77cf36b09b90bd86b9f14), uint256(0x20378b8e7bb5c53fdc6178ba0aa82998f4764c6b93768e92ae35e5fbb18c1fa6));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x21ef51e18672bdb4547cf70a9a7e591a6eb63aa4ca9fc255fdc3b6cec8be5308), uint256(0x26489d8a267e2261f621887704c36c43e7f03cd0ae29d91626379d3cf3a0042f));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x2643d0996ac07c81ed2656164eb71a99360d029e1cab833b546f2648cab44bda), uint256(0x15641ce1372e2f0fb393b39c64e17bb6dacd6864ceb32da1d2b178476da7541a));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x2b9a4e7f7cbb7d949a435262ef4dce40420d82abf1e5b96d35baec5a76ae3fba), uint256(0x03ab7fa51b4c0d58e836adc3260aa03ff08b77db0bfa36db07da5f767058fd4a));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x0d6e54586bd310b02017c9f53182e9416bcdae488500b046c7eabaf33cc1e826), uint256(0x2d01336868f5a6ceba694bf5f4b190e30b7b94d014f38bc9024c7884d2f0cd8e));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x1864e649faf91d316fa7f29bbd652cdd82a9bc9cabb76f717a2a630f6dd52a05), uint256(0x05e07e27107c51085f4bc4bea5897c93311b937334eb8f000e5e1ca2d5eb0f51));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x15a62b41a2a54b86efa040b7cc7bca8a2115c48d9355df5664e80f3338a1fdb2), uint256(0x2f6b332cfd560a047a69124a7e9b001dcb4d92263c92cfc488b9ac5b8b50d95d));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x1bb0e63d139f2181a9fdb0f0dc4c614a8ba4ef2fc98062f8da0ac3b7c1c32966), uint256(0x293fcce45ac6efd1b7f470572ce371facdf5f99e561469c5bf9a3debf9086e42));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x1f65ac73820170e59c81b3ae639bda8b4e812a5dce05fd2114f87560091be3a3), uint256(0x1579fb9e1d1c9df6e9d5bec3fadad2bf51744e764e5ee12727b631792b9b13f0));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x0c3e11a480295a5ff7fcbed3c148431bc0a653cdd61ed624583e74a6000537a4), uint256(0x13f7a57bbbe1fc221181b235cc3bf4346c977446617377359c7acb69583db4ca));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x1ff26235c6422a237f41974321b117f342b688be82853bb7407413819206bf2c), uint256(0x077466154defa83c8394c95ceedf90a2689457bcae1b5b3fcc3542bc0b84696a));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x19741f386fc91fa3a06a0201c31b8444d7755a99c2852f564e6a3e3c309eb6ca), uint256(0x20fb3f77b77c46c94789fe6493255efc1e0424a544809323a26b0d3b934c3e8a));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x1b066468f464bd6225727c62c38d4d7ffd6f760e10478419837047aa5d2217df), uint256(0x061c730045c6284ca35ba94d23f886a64affe8e1d59b5faa969917d349ca760d));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x008120e04492439904996a9f21c79f02f310b95f41ff1e5648ef6ac95e3321f4), uint256(0x2d19b58cd3991fdda966238dbd58faba3a42035c93cf70b30de9376578eac46d));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x0e8f06698e080f41036124a7f4a0469f0ee58a78d11ba7088a5190027eb9f170), uint256(0x0ec11eacf6ce7db5999d7346b2cc8187f68cf2e9aab2547a2bf7c733d2fc9ef4));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x24d54fbe4efafd3e0318fb4b718c7ee1740728022805b13744e6636688b0c287), uint256(0x17646176667371c3c4af140ba79099110ca516bf6a4fab8db7133eb2743d850b));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[39] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](39);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
