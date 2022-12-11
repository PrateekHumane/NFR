import React, {useContext} from "react";
import AppBar from "@mui/material/AppBar"
import Toolbar from "@mui/material/Toolbar";
import Typography from "@mui/material/Typography";
import Tooltip from "@mui/material/Tooltip";
import Chip from "@mui/material/Chip";
import Stack from '@mui/material/Stack';


import FilterNoneIcon from "@mui/icons-material/FilterNone";
import GppBadIcon from "@mui/icons-material/GppBad";
import PaidIcon from "@mui/icons-material/Paid";
import {Web3Context} from "../contexts/Web3Context";

const MyAppBar = () => {

    const {walletAddress} = useContext(Web3Context);

    return (
        <AppBar position="fixed" sx={{color: 'white',  zIndex: (theme) => theme.zIndex.drawer + 1}}>
            <Toolbar>
                <Typography variant="h6" noWrap component="div" sx={{flexGrow: 1}}>
                    Clipped drawer
                </Typography>
                <Stack direction="row" spacing={1}>
                    <Tooltip title="Connected wallet">
                        <Chip label={walletAddress}/>
                    </Tooltip>
                    <Tooltip title="Aritfacts">
                        <Chip icon={<FilterNoneIcon/>} label="3"/>
                    </Tooltip>
                    <Tooltip title="Contraband">
                        <Chip icon={<GppBadIcon/>} label="3"/>
                    </Tooltip>
                    <Tooltip title="MERGE tokens">
                        <Chip icon={<PaidIcon color="yellow"/>} label="3"/>
                    </Tooltip>
                </Stack>
            </Toolbar>
        </AppBar>
    );
}

export default MyAppBar;
