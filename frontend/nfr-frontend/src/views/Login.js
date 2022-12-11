import React, {useContext, useState} from "react";
import {Web3Context} from "contexts/Web3Context";
import { httpsCallable } from "firebase/functions";
import { signInWithCustomToken } from "firebase/auth";
import { functions, auth } from 'services';

const Login = () => {

    const {walletAddress} = useContext(Web3Context);
    const [loginPending, setLoginPending] = useState(false);

    const login = async () => {
        try {
            setLoginPending(true);
            // get nonce for this wallet
            const getNonceToSign = httpsCallable(functions, 'getNonceToSign');
            const {data : {nonce}} = await getNonceToSign({ address: walletAddress})
            // sign nonce
            const signature = await window.ethereum.request({
                method: 'personal_sign',
                params: [
                    nonce,
                    walletAddress,
                ],
            });
            const verifySignedMessage = httpsCallable(functions, 'verifySignedMessage');
            const {data: {token}} = await verifySignedMessage({ address: walletAddress, signature});

            await signInWithCustomToken(auth, token);


            setLoginPending(false);
        } catch (error) {
            setLoginPending(false);
            console.error(error);
            alert(error.message);
        }
    }
    return (
        <div>
        <button onClick={login}>
            {loginPending ? 'pending' : 'login'}
        </button>
            <p>
            {JSON.stringify(auth.currentUser)}
            </p>
        </div>
    );
}

export default Login;
