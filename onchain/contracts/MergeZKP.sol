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

contract MergeZKP {
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
        vk.alpha = Pairing.G1Point(uint256(0x0c46c02f2fbdc9c7cd15261a21b54d042e7bfb5c790e56565880ced6dac32501), uint256(0x20d5b3e52fd1aadf7fab4df611ef7f339c7b91ef8bf49ead7bfd42079819426d));
        vk.beta = Pairing.G2Point([uint256(0x23158db97bff1282c7920406583f3def1205c1766e59104c6f327de34615f4aa), uint256(0x2968e2d8bed65d7fe9169870fb12810d9baac9c0985235b4073d557a0b9d0c5f)], [uint256(0x0062ad797cd8c0b12efa92943f4462ea01995c614beb8159acf3442bc3f6c4de), uint256(0x11ba39c03c5474a09b776dcae292606cc94cf7972f76a54b23c3e2a6b33779c8)]);
        vk.gamma = Pairing.G2Point([uint256(0x185d1e448eab424159c6b7f91968543e1f50c54c877d433056946b40b88bc392), uint256(0x021a13c6fd0c549e0eeac86a0f08fe8d5dbe312046b0843a100a34260c8c7f45)], [uint256(0x0fb12cf0b384f2a890493f2b96676d54a0401811447efa72b488924f71fa4b78), uint256(0x0f64931226225f3935cffff58256c48c6f6d3616fe2e518fe2fc11ddc2c7b952)]);
        vk.delta = Pairing.G2Point([uint256(0x092b2ebe549dec9e3f4be90a0c0d40ba0deeeae7b5f21471478f511a19a3e930), uint256(0x20024edda3f867fac83a313ce42df4e3f721d47f621e2a70e203be76ac12e929)], [uint256(0x28bf41d4aa9bc88ef2141d48b6087b7897bd65c59c226f3f4b5b043aa4b46876), uint256(0x2512e84d3345a2a0fb1c43fba20ef28647b5a695bedc0e88dfe862a3437bb7f2)]);
        vk.gamma_abc = new Pairing.G1Point[](41);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x02839f87bb97741c36e8be54752079173238f2786b3794cc924845e43531d1bc), uint256(0x0909f10924760b3ebea8908d3ef64d52ea021ae473465a780a9ba81dec08999e));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x139091ad73832c08341559617608e01fe06e2103fd9f744b6580bdeea5c6e3d2), uint256(0x03d29d1f3522ec3f93184daf484446c35283a3266fd41b55d9789cbfa7e3c3b3));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0df77c7692725819d7a05f692e042b91b209c2dae9919395f2d811f3163fce38), uint256(0x2782ca95e2fe7fb7f0d8126d4a220937d980510e79124bb0d2ebaf81344abef0));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x1de80e2427395d81b5ae84c729540ed4c40a2e66abe77956bda29c274f27728a), uint256(0x265addb8effb0c3f69395c229a8f70c6dc0c4ef628761ff968e49edc95ceb0c2));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0f461300ac21408f117e9639db1e2b1b12a9287127809e0b716cddb2a90f1bed), uint256(0x0100b4344b1583d5f5046e320ad0797303cb5bda0f5344718bf01a09dc18b9be));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x1a758429ea02f225f4966b9d36df022c6e2bed6f936dd42c4f1a781d9baeb3e0), uint256(0x00a5b0895fdbd4a960c94f1418d2cee34cb4b12ec6a76e4d47e8a8c5205c1560));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x277ebc8ba0c165cfd2900f172c1b540cf087efea41ff84c34e04225cd34aa937), uint256(0x265b69a5870fcccb597af1164155b71cf1c92bd6a11f8d207bd1d74d7f99beec));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x2aa554aae339280fbd9e27be74c32f1f091dc73a2929aeebee7da430098be540), uint256(0x2e56170399e18f4136493bb3bcd8c4170232dd9459d469e6067149d786362ad3));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x23ed1bc77ed684af668c69911520285371be63e185e410046dc2ec380a1978fd), uint256(0x1eda8fc98683dcc3f9bd024977f688e08e0d07ac37d1633c654fd707b2ec42ac));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x2a82df9d1b2431f4d9879b5a2a3bece6e890665ac99419a34da62bcf34fde2d9), uint256(0x2ce7003a90c2836ffc19a32d8adcf97871f9d2d4c8ad30d039a0fb34596d8aa5));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x283b3ca4f3524ab11a9c8079f2993f80656e21c42a2f88f9332cf1ee73c131a2), uint256(0x1f994ece4620ec536d1f2e29ddb7dda44b71472af5cbc1f8d54b5f44a980cba7));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x0ab1d8eb929fcd2cbe391ef48cbca56c6829621b9d450f9a07dde32937b1b5c1), uint256(0x2a3a44f7e6c4572a0d728984807774f112ecd0881d8531e31d1e65a78a1ac475));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x0f70aff8ec36dfb27b4fc35eee8fbf86e05f21df395ef747869ba579b45c7145), uint256(0x03d7f5980a708ccd02997410332c8e213eee460ea318923156a71c30125e2abd));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x1951e5df99b7ed9181a26dec5a6b31515ffa5a443c55e887291c35fd0b4135e9), uint256(0x1569e779adf4fedba43b3f3a8a57297352948aed20a4f279faf5e5b8f7939201));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x02c15023abd6032d1b3a3de318bd650bcc879ee2951df3f6a66666fd0adc8853), uint256(0x09d72e4598f222a68d8d11f8e73559aab93932ef3d61b48c8c4d0cdb54bdf470));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x0763744bd020d2743e2ed7cf79d76388f605dddf2fa39efe0a40f4971855cc34), uint256(0x0f051a84fac83fb370cb4d92992aee69d607d1cba6ceec9a8567704870d8b449));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x2f7dfdc731874e7d403fd72db2a89f2dd1a096d3cca15d19e44f9e0da19c6cc2), uint256(0x17b03087546fa851d0bed2a243805d3dec7aa4686dd3df32d6f48676a5b0fc4e));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x2c7548f4fd8e171c186a9d2079fc4c518d50656679cbdee56a06e25af1e4acf6), uint256(0x0de9b7896b9ce64c67305214729953433c61ee5ee888b0bac3976681659feb4c));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x303ff3117f6a5ab46d6d8ce1f8ea5fbc7dad5084a60aa6ae3f903c2dc47fb46f), uint256(0x0ca55f7c2ea8b09884f5f7646fb524248475a087d09c3d23fd60e8319602be7b));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x2b86a1dc4f82b78941b0fd7e1ad6d40e1e2a9ef67dd8ad87decfdc4843436207), uint256(0x0b9453c5322cc64c4c610df127b106675b4fc176899d9d0b124cb03030d8f5b3));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x0a5cf66a82082d3431c9e41f3f6e44a545935d7f8d6b5972f89d8515ed01948d), uint256(0x2935396c29e4ebff4e27be03c136f05c163b32034300dacf38e34ce110bcc177));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x2777482054ecf13ab7d7d28f3df4deffc7770042191015dad25f226cfa56f9ef), uint256(0x03fb853ce29c7e0073b697e033262bb023bbe31414f90c83158d704fc0c5522d));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x0bbe27002a00a780ab95ebe39ced7cea5292f281c924097de732ea27ece3f56c), uint256(0x06210e48f5e3e4abac677486c442cae3e2ce69a0d8ab3e8ceb0df0034352d3b7));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x1b4b98b5950f2932873ee79636311268b45d1f1dc59b036bcd3de49add37ab3f), uint256(0x03dc8322d383ee8b080d8ae9c58f8d655a8a6b14b98f56170e6eb39921211cf3));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x094907ba7e83fb2cd2281e6605c213d2560c0002d673b366f423b3585dc0dbfc), uint256(0x16c57b502233c41beb9123df34927895d0500f5d8ae59ae0cce363bb0c1e8739));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x1efca27e1e576b2cce269ba566d21442352dbaf8b7aba4b9965f030cf452decc), uint256(0x185c31da9c14cd463ca7b011078b0c69374b17e056bdc627828ae6cf673dd7c2));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x218d60ad2a93b35f2017dd41a4ba6c0e1a95e1812e4c029dc4ec656ba229dbf1), uint256(0x0e87a5320005d00fc1c19339efaa6cc7b7177db499fa6d547c154482e096c3a0));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x2a17946429765bdd530e2c84a43d19d685c3d5779a31f17a1a8ba3fd96e6caa8), uint256(0x0352090b3b8bf0d8a79da77a56b2ea8f42ab230650ec5cd6ebb2c1f21ca01f28));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x14ff2946c41b41b2d1d691d2a38e52b3d3935e97919c2f0b36a85469bd7c0358), uint256(0x1b3a76372e309439e324777916715cef28a5090dd9ed00f57f11a6f2b456ae78));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x0f99c13453cbd4bcc868b9461f1edb04c710f7ed1f6bf78e84d929d36d63cfce), uint256(0x063eb7aafe4379a2bde4c7b9475b91d2d687d761f92135ff5992afef39350efd));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x171ab8098ad70eee142033405174162940e5a1b06a6d639c2894675132341891), uint256(0x119a981f95dbc2c1e1f0ed21a1a6a5519edb6e21d6f860f8b2ca6afc57179ca6));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x1ab4541d18ea05c33270f65dcb624b81e07ef01851c8dca47f36cd4d55608160), uint256(0x239411b5b4f377b7bc453d84416a91ba6d617554142b4ae0a197172c30e22810));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x01d38f93722a6a825d77f9cac380c99c9884fbbf7ec9a576150a4496ab0ba4e9), uint256(0x26fe32630ccfc1793ca0ef118bcc367c49bd3d2d76f27ab35e3ee445bfd4ce76));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x2c33da4373779716342ad679e0322d59f50c7b2d848d9753c60b5f45c307665c), uint256(0x18b47cc007a1865e6937625d63474b30004ca077149b72f6cfbbbafc4d9aae93));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x24000e081a987d288a9ce00a84e988e91818d2ca6e2cc84d4e904709f010eb14), uint256(0x0dc494d8f054176b60df9f62c3f56c2a878a04f64b275f929a9b4ed7c6d9a766));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x1d23a68ac447394cbe8afa24f8fef35798c640741eaed16ace3f36d06dea6cae), uint256(0x189925a465dd5e6398c4788f9be004d9b091c51602ba7552a13d2eac82b6349a));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x017d1340c2496d10262ba04953fc0f76a19f0d7cde79d3664b5204e922924d98), uint256(0x2a06bf0db8a744a1a7b559757386054d365522ffde269e4648d334c240a38464));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x1b24b366b2fc5de41cae4be89d4929fda8af640c24e4689ccbc8c5f2724b9225), uint256(0x15579b0a4c8342eb1a16c5daa79a216fccb83e82fd4c59871f0a54c57d38b6e2));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x2ac5b4cc14ac752ea4c22d7a8a64984c79f36cbfc9987d19d82e8bbf292c74b9), uint256(0x008d561ae461588999c4f6a3edb7be9fa2beeae81293560437872e303dae01d5));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x18d08dcc2db44165eef7490bd1c6e66127932365391a7efdf802227404efbce8), uint256(0x091cf3380c2d71a48009b861b082465b777feb1aa2fcecb2bde0d113e470d7e3));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x188a57f2a100fe58d5e3d594ef2ae19db7a237dc6dabc78a76c251eeaa97f203), uint256(0x2db39551c3a3ec7364523d79a45dbec27088f2e647cac8f5400431997a8bd33c));
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
            Proof memory proof, uint[40] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](40);
        
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
