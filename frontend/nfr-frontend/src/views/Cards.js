import React, {useContext, useEffect, useState} from 'react';
import {ContractsContext} from "../contexts/ContractsContext";
import {Web3Context} from "../contexts/Web3Context";
import {db, web3} from "services";
import {doc, getDoc} from "firebase/firestore";

import { styled } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { grey } from '@mui/material/colors';
import Button from '@mui/material/Button';
import Box from '@mui/material/Box';
import Skeleton from '@mui/material/Skeleton';
import Typography from '@mui/material/Typography';
import Drawer from '@mui/material/Drawer';

const StyledBox = styled(Box)(({theme}) => ({
    backgroundColor: theme.palette.mode === 'light' ? '#fff' : grey[800],
}));

const Puller = styled(Box)(({theme}) => ({
    width: 30,
    height: 6,
    backgroundColor: theme.palette.mode === 'light' ? grey[300] : grey[900],
    borderRadius: 3,
    position: 'absolute',
    top: 8,
    left: 'calc(50% - 15px)',
}));

const Cards = (props) => {

    const {NFRContract} = useContext(ContractsContext);
    const {walletAddress} = useContext(Web3Context);

    const [tokens, setTokens] = useState({});

    const [mergeOpen, setMergeOpen] = React.useState(true);
    const toggleDrawer = (newOpen) => () => {
        setMergeOpen(newOpen);
    };

    useEffect(() => {
        const getTokens = async () => {
            const balance = await NFRContract.methods.balanceOf(walletAddress).call();
            const myTokens = {};
            for (let i = 0; i < balance; i++) {
                const card = await NFRContract.methods.tokenOfOwnerByIndex(walletAddress, i).call();
                const tokenId = web3.utils.toHex(card).slice(2);
                const docRef = doc(db, "tokens", tokenId);
                const docSnap = await getDoc(docRef);
                myTokens[tokenId] = docSnap.data();
                // setTokens(tokens = > ({...tokens,tokenId: docSnap.data()}));
            }
            setTokens({...myTokens});
        }

        getTokens();
    }, [NFRContract, walletAddress])

    return (
        <>
            <div>
                {tokens && (
                    <ul>
                        {Object.keys(tokens).map(tokenId => (
                            <li key={tokenId}>{JSON.stringify(tokens[tokenId])}</li>
                        ))}
                    </ul>
                )}
            </div>

            <Drawer
                anchor={'bottom'}
                open={mergeOpen}
                onClose={toggleDrawer(false)}
            >
                <Skeleton variant="rectangular" height="100%" />
            </Drawer>
        </>
    );
}

export default Cards;
