import {Web3Context} from 'contexts/Web3Context';
import React, {useContext } from 'react';
import ConnectWallet from "views/ConnectWallet";
import {AuthContext} from "../contexts/AuthContext";
import Login from "views/Login";
import Console from "./Console";

const PrivateRoute = () => {

    const {walletAddress} = useContext(Web3Context);
    const {user} = useContext(AuthContext);

    console.log(user);

    if (!walletAddress)
        return (
            <ConnectWallet/>
        );
    else if (!user || `0x${user.uid}`!== walletAddress)
        return(
            <Login/>
        )
    else
        return (
            <Console/>
        );

};

export default PrivateRoute;
