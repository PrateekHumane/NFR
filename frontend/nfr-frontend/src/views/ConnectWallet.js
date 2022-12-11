import React, {useState} from "react";

const ConnectWallet = () => {

    const [walletPending, setWalletPending] = useState(false);

    const connectWallet = async () => {
        try {
            setWalletPending(true);
            await window.ethereum.request({method: 'eth_requestAccounts'});
            setWalletPending(false);
        } catch (error) {
            setWalletPending(false);
            console.error(error);
            alert(error.message);
        }
    }
    return (
        <button onClick={connectWallet}>
            {walletPending ? 'pending' : 'connectwallet'}
        </button>
    );
}

export default ConnectWallet;
